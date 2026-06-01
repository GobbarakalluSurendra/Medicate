import google.generativeai as genai
from flask import request, jsonify
from app.config import Config

# System prompt forcing specific behavior
SYSTEM_PROMPT = """
You are a specialized AI Medical Health Assistant. You are only permitted to answer health-related, wellness, diet, and fitness questions. 
If the user asks questions unrelated to health, medicine, diet, or workout suggestions, decline politely, saying: "I am an AI health assistant and can only answer health-related questions."

Rule Constraints:
1. Do NOT provide a direct medical diagnosis.
2. Do NOT write or prescribe specific medications or dosages.
3. Suggest lifestyle advice, general exercises/workouts, dietary recommendations, and general wellness guidance.
4. Always add a prominent medical disclaimer at the bottom: "Disclaimer: I am an AI, not a doctor. Please consult a qualified medical professional for specific diagnosis and treatments."
"""

# Configure Gemini if key is provided and not a placeholder
is_gemini_available = False
if Config.GEMINI_API_KEY and not Config.GEMINI_API_KEY.startswith("YOUR_"):
    try:
        genai.configure(api_key=Config.GEMINI_API_KEY)
        is_gemini_available = True
        print("[AI ASSISTANT] Gemini API configured successfully.")
    except Exception as e:
        print(f"[AI ASSISTANT] Error configuring Gemini API: {e}")

def chat_assistant(current_user):
    """
    Handles AI health chat queries.
    Uses Gemini API if available, else falls back to local rule-based responses.
    """
    data = request.get_json() or {}
    message = data.get('message', '').strip()

    if not message:
        return jsonify({'message': 'Message content is required.'}), 400

    # 1. Gemini API path
    if is_gemini_available:
        try:
            model = genai.GenerativeModel(
                'gemini-1.5-flash',
                system_instruction=SYSTEM_PROMPT
            )
            response = model.generate_content(message)
            reply = response.text
            
            # Simple heuristic: if refusal prompt matches or reply is very short and mentions refusal keywords
            is_refusal = "only answer health-related" in reply.lower()
            
            return jsonify({
                'reply': reply,
                'is_health_related': not is_refusal
            }), 200
        except Exception as e:
            print(f"[AI ASSISTANT] Gemini API execution failed: {e}. Falling back to rule-based engine.")

    # 2. Local rule-based fallback path
    message_lower = message.lower()
    
    # List of health-related keywords
    health_keywords = [
        'health', 'diet', 'workout', 'exercise', 'food', 'nutrition', 'symptom', 'pain', 'doctor',
        'medicine', 'sick', 'ill', 'fever', 'headache', 'calorie', 'muscle', 'fit', 'run', 'gym',
        'cardio', 'weight', 'heart', 'sleep', 'stress', 'sugar', 'blood', 'covid', 'flu', 'cough',
        'physique', 'vitamin', 'protein', 'carbs', 'injury', 'hydrate', 'wellness', 'injury'
    ]
    
    is_health_query = any(keyword in message_lower for keyword in health_keywords)
    
    if not is_health_query:
        return jsonify({
            'reply': "I am an AI health assistant and can only answer health-related questions.",
            'is_health_related': False
        }), 200

    disclaimer = "\n\nDisclaimer: I am an AI, not a doctor. Please consult a qualified medical professional for specific diagnosis and treatments."

    if any(k in message_lower for k in ['workout', 'exercise', 'gym', 'run', 'cardio', 'strength']):
        reply = (
            "### Workout Suggestions\n"
            "- **Cardiorespiratory Fitness:** Aim for 30 minutes of moderate aerobic exercise (brisk walking, cycling) 5 days a week.\n"
            "- **Strength Training:** Perform resistance exercises targeting major muscle groups (legs, back, chest, core) 2-3 times per week.\n"
            "- **Flexibility & Balance:** Include dynamic stretching before workouts and static stretches after to maintain joint health."
            + disclaimer
        )
    elif any(k in message_lower for k in ['diet', 'nutrition', 'food', 'eat', 'protein', 'calorie']):
        reply = (
            "### Dietary Guidelines\n"
            "- **Hydration:** Consume at least 8-10 glasses (around 2-2.5 liters) of water daily.\n"
            "- **Balanced Meals:** Fill half your plate with colorful vegetables, one-quarter with lean protein (chicken, fish, lentils), and one-quarter with whole grains (brown rice, whole wheat).\n"
            "- **Healthy Fats:** Incorporate avocados, nuts, seeds, and olive oil in moderation.\n"
            "- **Limit Processed Foods:** Minimize intake of added sugar, excess sodium, and trans fats."
            + disclaimer
        )
    else:
        reply = (
            "### General Health & Wellness Advice\n"
            "- **Sleep Hygiene:** Ensure you receive 7-9 hours of quality sleep per night.\n"
            "- **Regular Screenings:** Schedule routine checkups with your primary care provider.\n"
            "- **Mental Well-being:** Dedicate 10-15 minutes daily to stress-reducing activities, such as meditation or deep-breathing exercises.\n"
            "- **Active Lifestyle:** Take regular breaks to stand and stretch if your work is mostly sedentary."
            + disclaimer
        )

    return jsonify({
        'reply': reply,
        'is_health_related': True
    }), 200
