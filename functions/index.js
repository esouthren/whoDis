const functions = require('firebase-functions');
const {onCall, onRequest} = require('firebase-functions/v2/https');
const {defineSecret} = require('firebase-functions/params');
const admin = require('firebase-admin');
const {GoogleGenAI} = require('@google/genai');

// Initialize Firebase Admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

// Define the secrets
const openaiApiKey = defineSecret('OPENAI');
const nanobananaApiKey = defineSecret('NANOBANANA');
const slackApiKey = defineSecret('SLACK');

// OpenAI API endpoint
const OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions';

/**
 * Shared function to generate questions
 */
async function generateQuestionsLogic(numberOfPlayers) {
  const totalQuestions = numberOfPlayers * 6;
  const hardCount = numberOfPlayers * 2;
  const mediumCount = numberOfPlayers * 3;
  const easyCount = numberOfPlayers * 1;

  console.log(`Generating ${totalQuestions} questions for ${numberOfPlayers} players (${hardCount} hard, ${mediumCount} medium, ${easyCount} easy)`);

  // Prepare the prompt for OpenAI
  const prompt = `You are a question generator for a social party game where players answer questions about themselves, and others try to guess who answered what.

Generate exactly ${totalQuestions} unique questions for ${numberOfPlayers} players following these guidelines:

DIFFICULTY LEVELS:
- HARD (${hardCount} questions): Abstract, subtle, preference-based questions that many people might answer similarly (e.g., "What time did you wake up this morning?", "Do you prefer coffee or tea?", "What's your favorite color?")
- MEDIUM (${mediumCount} questions): Moderately identifying questions about hobbies, interests, or general lifestyle (e.g., "What is your favorite hobby?", "What type of music do you listen to?", "What's your dream vacation spot?")
- EASY (${easyCount} questions): Strong identifiers that are unique to individuals - location-specific, career-specific, or highly personal (e.g., "What city were you born in?", "What is your job or field of study?", "What's the name of your pet?")

REQUIREMENTS:
- Questions must be answerable by anyone
- Questions should encourage diverse, interesting answers
- Avoid yes/no questions
- Keep questions concise and clear
- Make questions feel conversational and fun
- Ensure variety across topics (don't repeat themes)
- Questions should be workplace-appropriate and should not make anyone feel embarrassment.
- Questions should be suitable for a multi-country audience and not be too US or Europe specific. 
- Players are software engineers, so some questions can have a slight tech focus, such as 'what's the first language you learned'.

Return ONLY a valid JSON array with ${totalQuestions} questions in this format:
[
  {"text": "question text here", "difficulty": "hard"},
  {"text": "question text here", "difficulty": "medium"},
  {"text": "question text here", "difficulty": "easy"},
  ...
]

Generate ${totalQuestions} unique questions now (${hardCount} hard, ${mediumCount} medium, ${easyCount} easy):`;

  // Call OpenAI API
  const response = await fetch(OPENAI_API_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${openaiApiKey.value()}`,
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: 'You are a helpful assistant that generates questions for party games. Always respond with valid JSON only.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      temperature: 0.9, // Higher creativity for variety
      max_tokens: 500,
    }),
  });

  if (!response.ok) {
    const errorData = await response.text();
    console.error('OpenAI API error:', errorData);
    throw new Error(`OpenAI API request failed: ${response.status}`);
  }

  const data = await response.json();
  const content = data.choices[0].message.content.trim();

  console.log('Raw OpenAI response:', content);

  // Parse the JSON response
  let questions;
  try {
    // Remove markdown code blocks if present
    const jsonContent = content.replace(/```json\n?|\n?```/g, '').trim();
    questions = JSON.parse(jsonContent);
  } catch (parseError) {
    console.error('Failed to parse OpenAI response:', content);
    throw new Error('Failed to parse questions from OpenAI response');
  }

  // Validate the response structure
  if (!Array.isArray(questions) || questions.length !== totalQuestions) {
    console.error(`Expected ${totalQuestions} questions but got ${questions.length}:`, questions);
    throw new Error(`Invalid questions format from OpenAI: expected ${totalQuestions}, got ${questions.length}`);
  }

  // Validate each question has required fields and count difficulties
  const difficultyCounts = {hard: 0, medium: 0, easy: 0};
  for (const q of questions) {
    if (!q.text || !q.difficulty) {
      throw new Error('Questions missing required fields');
    }
    // Normalize difficulty to lowercase
    q.difficulty = q.difficulty.toLowerCase();
    difficultyCounts[q.difficulty] = (difficultyCounts[q.difficulty] || 0) + 1;
  }

  console.log(`Successfully generated ${questions.length} questions (${difficultyCounts.hard} hard, ${difficultyCounts.medium} medium, ${difficultyCounts.easy} easy)`);

  return {
    success: true,
    questions: questions,
    totalQuestions: totalQuestions,
    numberOfPlayers: numberOfPlayers,
  };
}

/**
 * Firebase Cloud Function to generate unique questions for all players using OpenAI
 * Each player gets: 2 hard, 3 medium, 1 easy (6 questions total per player)
 * Returns all questions in one batch to reduce API calls and ensure variety
 */
/**
 * Firebase Callable Function (for Flutter app)
 */
exports.generatePlayerQuestions = onCall(
  {secrets: [openaiApiKey]},
  async (request) => {
    try {
      const {numberOfPlayers} = request.data;

      if (!numberOfPlayers || numberOfPlayers < 1) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'numberOfPlayers is required and must be at least 1'
        );
      }

      return await generateQuestionsLogic(numberOfPlayers);

    } catch (error) {
      console.error('Error generating questions:', error);
      
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      
      throw new functions.https.HttpsError(
        'internal',
        'Failed to generate questions',
        error.message
      );
    }
  }
);

/**
 * HTTP Function that accepts GCP identity tokens (for testing with curl)
 */
exports.generatePlayerQuestionsHttp = onRequest(
  {secrets: [openaiApiKey]},
  async (req, res) => {
    // Enable CORS
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');

    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }

    try {
      // Verify GCP identity token or Firebase ID token
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        res.status(401).json({error: 'Missing or invalid Authorization header'});
        return;
      }

      const token = authHeader.split('Bearer ')[1];
      
      // Verify token - try GCP identity token first, then Firebase ID token
      let tokenVerified = false;
      let tokenType = 'unknown';
      
      // First, try to verify as GCP identity token (from gcloud auth print-identity-token)
      try {
        const tokenInfoResponse = await fetch(
          `https://oauth2.googleapis.com/tokeninfo?id_token=${token}`
        );
        
        if (tokenInfoResponse.ok) {
          const tokenInfo = await tokenInfoResponse.json();
          
          // If tokeninfo endpoint returns successfully, it's a valid Google/GCP identity token
          // Accept it regardless of the specific audience format
          console.log('Verified as GCP/Google identity token');
          if (tokenInfo.email) {
            console.log('  Email:', tokenInfo.email);
          }
          if (tokenInfo.aud) {
            console.log('  Audience:', tokenInfo.aud);
          }
          tokenVerified = true;
          tokenType = 'gcp';
        } else {
          // If tokeninfo returns an error, it's not a valid Google token
          const errorText = await tokenInfoResponse.text();
          console.log('GCP tokeninfo endpoint returned error:', tokenInfoResponse.status, errorText);
        }
      } catch (gcpError) {
        console.log('GCP token verification failed, trying Firebase token:', gcpError.message);
      }
      
      // If GCP verification failed, try Firebase ID token
      // IMPORTANT: Only attempt Firebase verification if GCP verification completely failed
      if (!tokenVerified && tokenType !== 'gcp') {
        try {
          const decodedToken = await admin.auth().verifyIdToken(token);
          console.log('Verified as Firebase ID token for:', decodedToken.uid);
          tokenVerified = true;
          tokenType = 'firebase';
        } catch (firebaseError) {
          console.log('Firebase token verification failed:', firebaseError.message);
          // Don't log the full error details to avoid confusion
        }
      } else if (tokenVerified && tokenType === 'gcp') {
        console.log('Skipping Firebase verification - already verified as GCP token');
      }
      
      // If neither verification worked, reject the request
      if (!tokenVerified) {
        res.status(401).json({
          error: 'Invalid or unverifiable token',
          message: 'Token must be either a valid GCP identity token or Firebase ID token'
        });
        return;
      }

      // Parse request body
      let requestData;
      if (req.method === 'POST') {
        requestData = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
      } else {
        requestData = req.query;
      }

      const numberOfPlayers = requestData?.data?.numberOfPlayers || requestData?.numberOfPlayers;

      if (!numberOfPlayers || numberOfPlayers < 1) {
        res.status(400).json({
          error: 'numberOfPlayers is required and must be at least 1'
        });
        return;
      }

      const result = await generateQuestionsLogic(numberOfPlayers);
      res.status(200).json(result);

    } catch (error) {
      console.error('Error generating questions:', error);
      res.status(500).json({
        error: 'Failed to generate questions',
        message: error.message
      });
    }
  }
);

/**
 * Cloud function to generate a cartoon character portrait based on user's Slack profile picture
 * and their answers to 6 questions
 * 
 * Parameters:
 * - email: User's email address (for Slack lookup)
 * - questionsAndAnswers: String containing 6 questions and answers
 * 
 * Returns:
 * - imageUrl: URL of the generated image stored in Firebase Storage
 */
exports.generateCharacterPortrait = onCall(
  {secrets: [nanobananaApiKey, slackApiKey]},
  async (request) => {
    try {
      const {email, questionsAndAnswers} = request.data;

      // Validate input
      if (!email || !questionsAndAnswers) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'email and questionsAndAnswers are required'
        );
      }

      console.log(`Generating character portrait for email: ${email}`);

      // Step 1: Get Slack user profile picture
      const slackResponse = await fetch(
        `https://slack.com/api/users.lookupByEmail?email=${encodeURIComponent(email)}`,
        {
          headers: {
            'Authorization': `Bearer ${slackApiKey.value()}`,
          },
        }
      );

      if (!slackResponse.ok) {
        throw new Error(`Slack API request failed: ${slackResponse.status}`);
      }

      const slackData = await slackResponse.json();
      
      if (!slackData.ok) {
        throw new Error(`Slack API error: ${slackData.error || 'Unknown error'}`);
      }

      const userId = slackData.user.id;
      const profileImageUrl = slackData.user.profile?.image_512 || 
                              slackData.user.profile?.image_192 || 
                              slackData.user.profile?.image_72;

      if (!profileImageUrl) {
        throw new Error('No profile image found for user');
      }

      console.log(`Found Slack profile image: ${profileImageUrl}`);

      // Step 2: Download the Slack profile image
      const imageResponse = await fetch(profileImageUrl);
      if (!imageResponse.ok) {
        throw new Error(`Failed to download profile image: ${imageResponse.status}`);
      }
      
      const imageBuffer = await imageResponse.arrayBuffer();
      const imageBase64 = Buffer.from(imageBuffer).toString('base64');
      const imageMimeType = imageResponse.headers.get('content-type') || 'image/png';

      // Step 3: Generate image with Nano Banana (Gemini)
      const ai = new GoogleGenAI({apiKey: nanobananaApiKey.value()});

      // Create prompt incorporating the questions and answers
      const prompt = `Create a cartoon character portrait that incorporates the following preferences and answers:
${questionsAndAnswers}

The character should visually represent these preferences. For example, if they prefer coffee over tea, show them holding a coffee. Make it a fun, colorful cartoon style portrait.`;

      console.log('Generating image with Nano Banana...');

      const geminiResponse = await ai.models.generateContent({
        model: 'gemini-2.5-flash-image',
        contents: [
          prompt,
          {
            inlineData: {
              data: imageBase64,
              mimeType: imageMimeType,
            },
          },
        ],
      });

      // Extract the generated image from the response
      let generatedImageBuffer = null;
      for (const part of geminiResponse.candidates[0].content.parts) {
        if (part.text) {
          console.log('Gemini text response:', part.text);
        } else if (part.inlineData) {
          generatedImageBuffer = Buffer.from(part.inlineData.data, 'base64');
          break;
        }
      }

      if (!generatedImageBuffer) {
        throw new Error('No image generated in Gemini response');
      }

      console.log('Image generated successfully, uploading to Firebase Storage...');

      // Step 4: Upload to Firebase Storage
      const bucket = admin.storage().bucket('gs://xni75w9l4qcdp0p0xnbergczhoxgud.firebasestorage.app');
      const fileName = `character-portraits/${userId}_${Date.now()}.png`;
      const file = bucket.file(fileName);

      await file.save(generatedImageBuffer, {
        metadata: {
          contentType: 'image/png',
        },
      });

      // Make the file publicly accessible and get the URL
      await file.makePublic();
      const imageUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;

      console.log(`Image uploaded successfully: ${imageUrl}`);

      return {
        success: true,
        imageUrl: imageUrl,
      };

    } catch (error) {
      console.error('Error generating character portrait:', error);
      
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      
      throw new functions.https.HttpsError(
        'internal',
        'Failed to generate character portrait',
        error.message
      );
    }
  }
);
