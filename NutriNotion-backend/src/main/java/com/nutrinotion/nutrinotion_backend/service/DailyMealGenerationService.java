package com.nutrinotion.nutrinotion_backend.service;

import com.nutrinotion.nutrinotion_backend.dto.AiMealResponse;
import com.nutrinotion.nutrinotion_backend.dto.AiMealResponse.AiMealItem;
import com.nutrinotion.nutrinotion_backend.dto.DailyMealPlanResponse;
import com.nutrinotion.nutrinotion_backend.dto.MealItemDto;
import com.nutrinotion.nutrinotion_backend.model.*;
import com.nutrinotion.nutrinotion_backend.repo.*;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDate;
import java.time.format.TextStyle;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
public class DailyMealGenerationService {

    @Value("${gemini.api.key}")
    private String geminiApiKey;

    @Value("${gemini.api.base.url}")
    private String geminiBaseUrl;

    @Value("${gemini.api.model}")
    private String geminiModel;

    @Value("${gemini.api.url}")
    private String geminiApiUrl;

    @Value("${gemini.api.fallback.model}")
    private String geminiFallbackModel;

    @Value("${gemini.api.fallback.url}")
    private String geminiApiFallbackUrl;

    @Value("${gemini.api.max-retries:2}")
    private int maxRetries;

    @Autowired private UserRepo userRepo;
    @Autowired private UserProfileRepo userProfileRepo;
    @Autowired private MessMenuRepo messMenuRepo;
    @Autowired private PersonalizedMealItemRepo mealItemRepo;
    @Autowired private CalorieTrackingService calorieTrackingService;
    @Autowired private RestTemplate restTemplate;

    @PostConstruct
    public void init() {
        System.out.println("╔══════════════════════════════════════════════════════════════╗");
        System.out.println("║           Gemini API Configuration (resolved)                ║");
        System.out.println("╠══════════════════════════════════════════════════════════════╣");
        System.out.println("║ Primary  model : " + geminiModel);
        System.out.println("║ Primary  URL   : " + geminiApiUrl);
        System.out.println("║ Fallback model : " + geminiFallbackModel);
        System.out.println("║ Fallback URL   : " + geminiApiFallbackUrl);
        System.out.println("║ Max retries    : " + maxRetries);
        System.out.println("╚══════════════════════════════════════════════════════════════╝");
    }

    // ─────────────────────────────────────────────────────────────────────────
    // POST /api/personalized-meals/{userId}/generate-today
    // Idempotent: returns cached items if already generated today.
    // ─────────────────────────────────────────────────────────────────────────
    @Transactional
    public DailyMealPlanResponse generateToday(Long userId) {
        LocalDate today = LocalDate.now();
        if (mealItemRepo.existsByUser_IdAndMealDate(userId, today)) {
            return buildResponse(userId, today);
        }
        return generateAndSave(userId, today);
    }

    // GET /api/personalized-meals/{userId}/today — auto-generates if needed
    @Transactional
    public DailyMealPlanResponse getToday(Long userId) {
        LocalDate today = LocalDate.now();
        if (mealItemRepo.existsByUser_IdAndMealDate(userId, today)) {
            return buildResponse(userId, today);
        }
        return generateAndSave(userId, today);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Core generation — calls Gemini, persists items, seeds calorie tracking
    // ─────────────────────────────────────────────────────────────────────────
    private DailyMealPlanResponse generateAndSave(Long userId, LocalDate today) {
        System.out.println("[MealGen] generateAndSave userId=" + userId + " date=" + today);

        User user = userRepo.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found: " + userId));

        UserProfile profile = userProfileRepo.findByUser_Id(userId)
                .orElseThrow(() -> new RuntimeException("Profile not found for user: " + userId));

        String todayName = today.getDayOfWeek().getDisplayName(TextStyle.FULL, Locale.ENGLISH);
        System.out.println("[MealGen] todayName=" + todayName);

        MessMenu menu = messMenuRepo.findByDayOfWeekIgnoreCase(todayName)
                .orElseThrow(() -> new RuntimeException("No mess menu found for: " + todayName));

        int targetCalories = profile.getDailyCalorieTarget() != null
                ? profile.getDailyCalorieTarget() : 2000;

        // Call Gemini and parse structured response
        String prompt  = buildPrompt(profile, menu, todayName, targetCalories);
        String rawJson = callGemini(prompt);
        System.out.println("[MealGen] Raw Gemini response:\n" + rawJson);
        AiMealResponse aiMeal = parseAiResponse(rawJson);

        // Persist each item
        List<PersonalizedMealItem> savedItems = new ArrayList<>();
        savedItems.addAll(saveItems(user, today, "breakfast", aiMeal.getBreakfast()));
        savedItems.addAll(saveItems(user, today, "lunch",     aiMeal.getLunch()));
        savedItems.addAll(saveItems(user, today, "snacks",    aiMeal.getSnacks()));
        savedItems.addAll(saveItems(user, today, "dinner",    aiMeal.getDinner()));

        // Seed calorie tracking row for today (consumed = 0, target = profile target)
        calorieTrackingService.getOrCreate(userId, today, targetCalories);

        System.out.println("[MealGen] Saved " + savedItems.size() + " meal items for userId=" + userId);
        return buildResponse(userId, today, savedItems, targetCalories, aiMeal.getNutritionTip());
    }

    private List<PersonalizedMealItem> saveItems(
            User user, LocalDate date, String mealType, List<AiMealItem> aiItems) {
        if (aiItems == null || aiItems.isEmpty()) return Collections.emptyList();
        List<PersonalizedMealItem> items = new ArrayList<>();
        for (AiMealItem ai : aiItems) {
            PersonalizedMealItem item = new PersonalizedMealItem();
            item.setUser(user);
            item.setMealDate(date);
            item.setMealType(mealType);
            item.setFoodName(ai.getFoodName() != null ? ai.getFoodName() : "Unknown");
            item.setQuantity(ai.getQuantity() != null ? ai.getQuantity() : "1 serving");
            item.setCalories(ai.getCalories() != null ? ai.getCalories() : 0);
            item.setChecked(false);
            items.add(mealItemRepo.save(item));
        }
        return items;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Check / Uncheck a meal item  →  PUT /api/personalized-meals/item/{id}/check
    // ─────────────────────────────────────────────────────────────────────────
    @Transactional
    public MealItemDto toggleCheck(Long itemId, boolean checked) {
        PersonalizedMealItem item = mealItemRepo.findById(itemId)
                .orElseThrow(() -> new RuntimeException("Meal item not found: " + itemId));

        boolean wasChecked = item.isChecked();
        if (wasChecked == checked) {
            // No state change — return as-is
            return toItemDto(item);
        }

        item.setChecked(checked);
        mealItemRepo.save(item);

        int delta = checked ? (item.getCalories() != null ? item.getCalories() : 0)
                            : -(item.getCalories() != null ? item.getCalories() : 0);
        calorieTrackingService.applyDelta(item.getUser().getId(), item.getMealDate(), delta);

        return toItemDto(item);
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Build response from persisted items
    // ─────────────────────────────────────────────────────────────────────────
    private DailyMealPlanResponse buildResponse(Long userId, LocalDate date) {
        List<PersonalizedMealItem> items = mealItemRepo.findByUser_IdAndMealDate(userId, date);
        // Fetch calorie tracking to get targetCalories
        int target = calorieTrackingService.getSummary(userId).getTargetCalories();
        // Reconstruct nutritionTip — store a placeholder (it's not persisted separately)
        return buildResponse(userId, date, items, target, null);
    }

    private DailyMealPlanResponse buildResponse(
            Long userId, LocalDate date, List<PersonalizedMealItem> items,
            int targetCalories, String nutritionTip) {

        String dayName = date.getDayOfWeek().getDisplayName(TextStyle.FULL, Locale.ENGLISH);

        List<MealItemDto> breakfast = filterAndMap(items, "breakfast");
        List<MealItemDto> lunch     = filterAndMap(items, "lunch");
        List<MealItemDto> snacks    = filterAndMap(items, "snacks");
        List<MealItemDto> dinner    = filterAndMap(items, "dinner");

        int totalSuggested = items.stream()
                .mapToInt(i -> i.getCalories() != null ? i.getCalories() : 0)
                .sum();

        return new DailyMealPlanResponse(
                userId, date, dayName,
                breakfast, lunch, snacks, dinner,
                totalSuggested, targetCalories,
                nutritionTip
        );
    }

    private List<MealItemDto> filterAndMap(List<PersonalizedMealItem> items, String mealType) {
        return items.stream()
                .filter(i -> mealType.equalsIgnoreCase(i.getMealType()))
                .map(this::toItemDto)
                .collect(Collectors.toList());
    }

    private MealItemDto toItemDto(PersonalizedMealItem i) {
        return new MealItemDto(
                i.getId(), i.getFoodName(), i.getQuantity(),
                i.getCalories(), i.getMealType(), i.isChecked()
        );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Prompt builder — instructs Gemini to return structured JSON item arrays
    // ─────────────────────────────────────────────────────────────────────────
    private String buildPrompt(UserProfile profile, MessMenu menu,
                               String dayName, int targetCalories) {
        return """
                You are a certified nutritionist AI. Your task is to recommend a personalized
                daily meal plan for TODAY ONLY, using STRICTLY the food items listed in today's
                mess menu below. Do NOT invent or add any food not in the mess menu.

                === USER PROFILE ===
                Name            : %s
                Age             : %d
                Gender          : %s
                Diet Preference : %s
                Fitness Goal    : %s
                Daily Calorie Target : %d kcal
                Allergies       : %s
                Disliked Foods  : %s

                === TODAY'S MESS MENU (%s) ===
                Breakfast : %s
                Lunch     : %s
                Snacks    : %s
                Dinner    : %s

                === STRICT INSTRUCTIONS ===
                1. Only recommend items that appear in the mess menu above.
                2. Exclude ANY item the user is allergic to or dislikes.
                3. Respect diet preference strictly (Vegetarian/Vegan = no meat/fish/egg).
                4. Total calories across all meals must be close to the daily calorie target (%d kcal).
                5. Each item MUST have: foodName, quantity (human-readable), calories (integer).
                6. Return ONLY a valid JSON object. No markdown. No explanation. No extra text.
                7. If a meal has no suitable items, return an empty array [] for that key.

                === REQUIRED JSON FORMAT (return exactly this structure) ===
                {
                  "breakfast": [
                    {"foodName": "item name", "quantity": "1 serving", "calories": 200}
                  ],
                  "lunch": [
                    {"foodName": "item name", "quantity": "1 cup", "calories": 300}
                  ],
                  "snacks": [],
                  "dinner": [
                    {"foodName": "item name", "quantity": "1 plate", "calories": 400}
                  ],
                  "totalCalories": 900,
                  "nutritionTip": "One short personalized tip for the user's goal."
                }
                """.formatted(
                nullSafe(profile.getName()),
                profile.getAge() != null ? profile.getAge() : 0,
                nullSafe(profile.getGender()),
                nullSafe(profile.getDietaryPreferences()),
                nullSafe(profile.getGoal()),
                targetCalories,
                nullSafe(profile.getAllergies()),
                nullSafe(profile.getDislikedFoods()),
                dayName,
                nullSafe(menu.getBreakfast()),
                nullSafe(menu.getLunch()),
                nullSafe(menu.getSnacks()),
                nullSafe(menu.getDinner()),
                targetCalories
        );
    }

    private String nullSafe(String s) {
        return (s == null || s.isBlank()) ? "None" : s;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Call Gemini — retry on 429, fallback on 404, structured error messages
    // ─────────────────────────────────────────────────────────────────────────
    private String callGemini(String prompt) {
        String[][] models = {
            { geminiApiUrl,         geminiModel         },
            { geminiApiFallbackUrl, geminiFallbackModel }
        };
        StringBuilder notFoundModels = new StringBuilder();

        for (String[] modelEntry : models) {
            String modelUrl  = modelEntry[0];
            String modelName = modelEntry[1];
            System.out.println("[Gemini] Attempting model=" + modelName + " url=" + modelUrl);

            for (int attempt = 1; attempt <= maxRetries + 1; attempt++) {
                try {
                    String result = doCallGemini(prompt, modelUrl);
                    System.out.println("[Gemini] ✓ Success model=" + modelName + " attempt=" + attempt);
                    return result;
                } catch (org.springframework.web.client.HttpClientErrorException e) {
                    int status = e.getStatusCode().value();
                    if (status == 404) {
                        System.out.println("[Gemini] ✗ 404 for model=" + modelName + " — trying fallback.");
                        notFoundModels.append(modelName).append(" (404), ");
                        break;
                    } else if (status == 429) {
                        System.out.println("[Gemini] ⚠ 429 model=" + modelName
                                + " attempt=" + attempt + "/" + (maxRetries + 1));
                        if (attempt > maxRetries) { break; }
                        long waitMs = parseRetryDelayMs(e.getResponseBodyAsString());
                        System.out.println("[Gemini] Waiting " + (waitMs / 1000) + "s...");
                        try { Thread.sleep(waitMs); }
                        catch (InterruptedException ie) {
                            Thread.currentThread().interrupt();
                            throw new RuntimeException("Retry interrupted", ie);
                        }
                    } else {
                        throw new RuntimeException(
                            "Gemini HTTP " + status + " for model=\"" + modelName
                            + "\": " + e.getResponseBodyAsString(), e);
                    }
                }
            }
        }

        if (!notFoundModels.isEmpty()) {
            throw new RuntimeException(
                "All configured Gemini models returned 404: [" + notFoundModels.toString().stripTrailing() + "]. "
                + "Call GET /api/personalized-meals/gemini/models to list available models, "
                + "then update application.properties.");
        }
        throw new RuntimeException(
            "All Gemini models exhausted quota. Please wait and try again. "
            + "See: https://ai.google.dev/gemini-api/docs/rate-limits");
    }

    @SuppressWarnings("unchecked")
    private String doCallGemini(String prompt, String modelUrl) {
        String url = modelUrl + "?key=" + geminiApiKey;
        Map<String, Object> textPart    = Map.of("text", prompt);
        Map<String, Object> content     = Map.of("parts", List.of(textPart));
        Map<String, Object> requestBody = Map.of("contents", List.of(content));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

        ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                url, HttpMethod.POST, entity,
                new ParameterizedTypeReference<Map<String, Object>>() {});

        if (!response.getStatusCode().is2xxSuccessful() || response.getBody() == null) {
            throw new RuntimeException("Gemini call failed: " + response.getStatusCode());
        }
        try {
            List<Map<String, Object>> candidates =
                    (List<Map<String, Object>>) response.getBody().get("candidates");
            Map<String, Object> contentMap =
                    (Map<String, Object>) candidates.get(0).get("content");
            List<Map<String, Object>> parts =
                    (List<Map<String, Object>>) contentMap.get("parts");
            return (String) parts.get(0).get("text");
        } catch (Exception e) {
            throw new RuntimeException("Failed to extract text from Gemini response: "
                    + response.getBody(), e);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Parse Gemini's structured JSON response into AiMealResponse
    // ─────────────────────────────────────────────────────────────────────────
    private AiMealResponse parseAiResponse(String raw) {
        // Strip markdown fences
        String json = raw.replaceAll("(?s)```json\\s*", "")
                         .replaceAll("(?s)```\\s*", "")
                         .trim();
        int start = json.indexOf('{');
        int end   = json.lastIndexOf('}');
        if (start == -1 || end == -1) {
            throw new RuntimeException("No JSON object in AI response: " + raw);
        }
        json = json.substring(start, end + 1);

        AiMealResponse meal = new AiMealResponse();
        meal.setBreakfast(parseItemArray(json, "breakfast"));
        meal.setLunch(parseItemArray(json, "lunch"));
        meal.setSnacks(parseItemArray(json, "snacks"));
        meal.setDinner(parseItemArray(json, "dinner"));
        meal.setTotalCalories(extractInt(json, "totalCalories"));
        meal.setNutritionTip(extractString(json, "nutritionTip"));
        return meal;
    }

    /**
     * Extracts a JSON array for the given meal key and parses each item object.
     * Handles: "breakfast": [ {"foodName":"...", "quantity":"...", "calories": 200}, ... ]
     */
    private List<AiMealItem> parseItemArray(String json, String key) {
        // Extract the array content between the outermost [ ] for this key
        Pattern arrayPattern = Pattern.compile(
                "\"" + key + "\"\\s*:\\s*\\[(.*?)\\]",
                Pattern.DOTALL);
        Matcher arrayMatcher = arrayPattern.matcher(json);
        if (!arrayMatcher.find()) return Collections.emptyList();

        String arrayContent = arrayMatcher.group(1).trim();
        if (arrayContent.isEmpty()) return Collections.emptyList();

        List<AiMealItem> items = new ArrayList<>();
        // Split on object boundaries: extract each { ... } block
        Pattern objPattern = Pattern.compile("\\{([^{}]*)\\}", Pattern.DOTALL);
        Matcher objMatcher = objPattern.matcher(arrayContent);
        while (objMatcher.find()) {
            String obj = objMatcher.group(0);
            String foodName = extractString(obj, "foodName");
            String quantity = extractString(obj, "quantity");
            Integer calories = extractInt(obj, "calories");
            if (foodName != null && !foodName.isBlank()) {
                items.add(new AiMealItem(
                        foodName,
                        quantity != null ? quantity : "1 serving",
                        calories != null ? calories : 0
                ));
            }
        }
        return items;
    }

    private String extractString(String json, String field) {
        Pattern p = Pattern.compile("\"" + field + "\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"");
        Matcher m = p.matcher(json);
        return m.find() ? m.group(1) : null;
    }

    private Integer extractInt(String json, String field) {
        Pattern p = Pattern.compile("\"" + field + "\"\\s*:\\s*(\\d+)");
        Matcher m = p.matcher(json);
        return m.find() ? Integer.parseInt(m.group(1)) : null;
    }

    private long parseRetryDelayMs(String errorBody) {
        try {
            Matcher m = Pattern.compile("\"retryDelay\"\\s*:\\s*\"(\\d+(?:\\.\\d+)?)s\"")
                    .matcher(errorBody);
            if (m.find()) return (long)(Double.parseDouble(m.group(1)) * 1000) + 2000;
        } catch (Exception ignored) {}
        return 62_000L;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Debug — list available Gemini models for this API key
    // ─────────────────────────────────────────────────────────────────────────
    @SuppressWarnings("unchecked")
    public List<Map<String, Object>> listSupportedModels() {
        String listUrl = geminiBaseUrl + "?key=" + geminiApiKey;
        try {
            ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                    listUrl, HttpMethod.GET,
                    new HttpEntity<>(new HttpHeaders()),
                    new ParameterizedTypeReference<Map<String, Object>>() {});
            if (response.getBody() == null)
                throw new RuntimeException("Empty response from Gemini models endpoint");
            List<Map<String, Object>> models =
                    (List<Map<String, Object>>) response.getBody().get("models");
            if (models == null)
                throw new RuntimeException("No 'models' field in response: " + response.getBody());
            System.out.println("[Gemini] Found " + models.size() + " models");
            return models;
        } catch (org.springframework.web.client.HttpClientErrorException e) {
            throw new RuntimeException("Failed to list Gemini models (HTTP "
                    + e.getStatusCode() + "): " + e.getResponseBodyAsString(), e);
        }
    }
}
