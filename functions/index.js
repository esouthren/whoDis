const functions = require('firebase-functions');
const { onCall, onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');
const { GoogleGenAI } = require('@google/genai');

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
async function generateQuestionsLogic() {
  const functionStartTime = Date.now();
  const totalQuestions = 6;
  const hardCount = 2;
  const mediumCount = 3;
  const easyCount = 1;

  console.log(`[DEBUG] Starting question generation for 1 player`);
  console.log(`[DEBUG] Target: ${totalQuestions} questions (${hardCount} hard, ${mediumCount} medium, ${easyCount} easy)`);

  // Prepare the prompt for OpenAI
  const prompt = `You are a question generator for a social party game where players answer questions about themselves, and others try to guess who answered what.

Generate exactly ${totalQuestions} unique questions for 1 player following these guidelines:

DIFFICULTY LEVELS:
- HARD (${hardCount} questions): Abstract, subtle, preference-based questions that many people might answer similarly (e.g., "What time did you wake up this morning?", "Do you prefer coffee or tea?", "What's your favorite color?")
- MEDIUM (${mediumCount} questions): Moderately identifying questions about hobbies, interests, or general lifestyle (e.g., "What is your favorite hobby?", "What type of music do you listen to?", "What's your dream vacation spot?")
- EASY (${easyCount} questions): Strong identifiers that are unique to individuals - location-specific, career-specific, or highly personal (e.g., "What city were you born in?", "What is your job or field of study?", "What's the name of your pet?")

REQUIREMENTS:
- Questions must be answerable by anyone
- Questions should encourage diverse, interesting answers
- Avoid yes/no questions. Ensure that questions can be answered in a few words rather than a paragraph.
- Keep questions concise and clear
- Make questions feel conversational and fun
- Ensure variety across topics (don't repeat themes)
- Questions should be workplace-appropriate and should not make anyone feel embarrassment.
- Questions should be suitable for a multi-country audience and not be too US or Europe specific. 
- Players are software engineers, so some questions can have a tech focus. 
- Don't ask what people's job/skills are - as a group, we already know that.
 
Return ONLY a valid JSON array with exactly ${totalQuestions} questions in this format:
[
  {"text": "question text here", "difficulty": "hard"},
  {"text": "question text here", "difficulty": "hard"},
  {"text": "question text here", "difficulty": "medium"},
  {"text": "question text here", "difficulty": "medium"},
  {"text": "question text here", "difficulty": "medium"},
  {"text": "question text here", "difficulty": "easy"}
]

Generate exactly ${totalQuestions} unique questions now (${hardCount} hard, ${mediumCount} medium, ${easyCount} easy):`;

  // Calculate max_tokens for 6 questions
  // Each question is roughly 80-100 tokens (JSON structure + question text + spacing)
  // Be more generous with estimates to avoid truncation
  const estimatedTokensPerQuestion = 100;
  // Use 2x buffer for safety to ensure we never truncate
  const maxTokens = Math.ceil(totalQuestions * estimatedTokensPerQuestion * 2);
  // Cap at reasonable maximum (gpt-4o-mini supports up to 128k context)
  const maxTokensCapped = Math.min(maxTokens, 4000);

  console.log(`[DEBUG] Token allocation: max_tokens=${maxTokensCapped} for ${totalQuestions} questions`);
  const apiCallStartTime = Date.now();

  // Call OpenAI API
  console.log('[DEBUG] Calling OpenAI API...');
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
      temperature: 1.6, // Higher creativity for more variance and randomness
      max_tokens: maxTokensCapped,
    }),
  });

  if (!response.ok) {
    const errorData = await response.text();
    console.error('OpenAI API error:', errorData);
    throw new Error(`OpenAI API request failed: ${response.status}`);
  }

  const data = await response.json();
  const apiCallDuration = Date.now() - apiCallStartTime;

  const content = data.choices[0].message.content.trim();
  const finishReason = data.choices[0].finish_reason;
  const usage = data.usage;

  console.log(`[DEBUG] OpenAI API call completed in ${apiCallDuration}ms`);
  console.log(`[DEBUG] Response details:`);
  console.log(`  - Response length: ${content.length} characters`);
  console.log(`  - Finish reason: ${finishReason}`);
  if (usage) {
    console.log(`  - Token usage: prompt=${usage.prompt_tokens}, completion=${usage.completion_tokens}, total=${usage.total_tokens}`);
    console.log(`  - Token efficiency: ${(usage.completion_tokens / totalQuestions).toFixed(1)} tokens per question`);
  } else {
    console.log(`  - Token usage: N/A`);
  }

  // Check if response was truncated (finish_reason will be 'length' if truncated)
  if (finishReason === 'length') {
    console.error('OpenAI response was truncated due to max_tokens limit');
    console.error('Response length:', content.length);
    console.error('Completion tokens used:', usage?.completion_tokens);
    console.error('Max tokens allowed:', maxTokensCapped);
    console.error('Last 500 chars:', content.slice(-500));
    throw new Error(`Response was truncated. Generated ${totalQuestions} questions may require more tokens. Consider increasing max_tokens.`);
  }

  // Check if content appears to be truncated by looking for incomplete JSON
  const trimmedContent = content.trim();
  if (!trimmedContent.endsWith(']') && !trimmedContent.endsWith('}')) {
    console.warn('Response may be truncated - does not end with valid JSON closing bracket');
    console.warn('Last 200 chars:', trimmedContent.slice(-200));
  }

  // Parse the JSON response
  const parseStartTime = Date.now();
  let questions;
  try {
    // Remove markdown code blocks if present
    let jsonContent = content.replace(/```json\n?|\n?```/g, '').trim();

    // Try to extract JSON array if there's garbage text
    // Find the first '[' and try to find the matching closing ']'
    const firstBracket = jsonContent.indexOf('[');
    if (firstBracket > 0) {
      console.warn(`Found text before JSON array at position ${firstBracket}, attempting to extract JSON`);
    }

    if (firstBracket >= 0) {
      // Extract from first bracket onwards
      jsonContent = jsonContent.substring(firstBracket);

      // Try to find the last valid closing bracket
      let bracketCount = 0;
      let lastValidBracket = -1;
      for (let i = 0; i < jsonContent.length; i++) {
        if (jsonContent[i] === '[') bracketCount++;
        if (jsonContent[i] === ']') {
          bracketCount--;
          if (bracketCount === 0) {
            lastValidBracket = i;
          }
        }
      }

      if (lastValidBracket > 0 && bracketCount !== 0) {
        console.warn(`Unbalanced brackets detected, truncating at position ${lastValidBracket + 1}`);
        jsonContent = jsonContent.substring(0, lastValidBracket + 1);
      }
    }

    questions = JSON.parse(jsonContent);
    const parseDuration = Date.now() - parseStartTime;
    console.log(`[DEBUG] JSON parsing completed in ${parseDuration}ms`);
  } catch (parseError) {
    const parseDuration = Date.now() - parseStartTime;
    console.error(`[DEBUG] JSON parsing failed after ${parseDuration}ms. Content length:`, content.length);
    console.error('First 1000 chars:', content.substring(0, 1000));
    console.error('Last 1000 chars:', content.substring(Math.max(0, content.length - 1000)));
    throw new Error(`Failed to parse questions from OpenAI response: ${parseError.message}`);
  }

  // Validate the response structure
  const validationStartTime = Date.now();
  if (!Array.isArray(questions)) {
    console.error('OpenAI response is not an array:', questions);
    throw new Error('Invalid questions format from OpenAI: response is not an array');
  }

  // Handle cases where OpenAI returns more or fewer questions than requested
  if (questions.length < totalQuestions) {
    console.error(`Expected ${totalQuestions} questions but got ${questions.length}:`, questions);
    throw new Error(`Insufficient questions from OpenAI: expected ${totalQuestions}, got ${questions.length}`);
  }

  // If we got more questions than needed, trim to the exact count
  if (questions.length > totalQuestions) {
    console.warn(`OpenAI returned ${questions.length} questions, but only ${totalQuestions} were requested. Trimming to requested count.`);
    questions = questions.slice(0, totalQuestions);
  }

  // Validate each question has required fields and count difficulties
  const difficultyCounts = { hard: 0, medium: 0, easy: 0 };
  for (const q of questions) {
    if (!q.text || !q.difficulty) {
      throw new Error('Questions missing required fields');
    }
    // Normalize difficulty to lowercase
    q.difficulty = q.difficulty.toLowerCase();
    difficultyCounts[q.difficulty] = (difficultyCounts[q.difficulty] || 0) + 1;
  }

  const validationDuration = Date.now() - validationStartTime;
  const totalDuration = Date.now() - functionStartTime;

  console.log(`[DEBUG] Validation completed in ${validationDuration}ms`);
  console.log(`[DEBUG] Successfully generated ${questions.length} questions (${difficultyCounts.hard} hard, ${difficultyCounts.medium} medium, ${difficultyCounts.easy} easy)`);
  console.log(`[DEBUG] ====== PERFORMANCE SUMMARY ======`);
  console.log(`[DEBUG] Total function duration: ${totalDuration}ms (${(totalDuration / 1000).toFixed(2)}s)`);
  console.log(`[DEBUG] Breakdown:`);
  console.log(`[DEBUG]   - OpenAI API call: ${apiCallDuration}ms (${((apiCallDuration / totalDuration) * 100).toFixed(1)}%)`);
  if (usage) {
    console.log(`[DEBUG]   - Token usage: ${usage.total_tokens} total (${usage.prompt_tokens} prompt + ${usage.completion_tokens} completion)`);
    console.log(`[DEBUG]   - Cost estimate: ~$${((usage.prompt_tokens * 0.15 + usage.completion_tokens * 0.6) / 1000000).toFixed(4)} (gpt-4o-mini pricing)`);
  }
  console.log(`[DEBUG] =================================`);

  return {
    success: true,
    questions: questions,
    totalQuestions: totalQuestions,
  };
}

/**
 * Firebase Callable Function (for Flutter app)
 * Generates 6 unique questions for a single player: 2 hard, 3 medium, 1 easy
 * The frontend should call this function once per player
 */
exports.generatePlayerQuestions = onCall(
  {
    secrets: [openaiApiKey],
    timeoutSeconds: 60, // 1 minute timeout is sufficient for 6 questions
    memory: '512MiB' // Reduced memory since we're only generating 6 questions
  },
  async (request) => {
    try {
      return await generateQuestionsLogic();

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
 * Generates 6 unique questions for a single player: 2 hard, 3 medium, 1 easy
 */
exports.generatePlayerQuestionsHttp = onRequest(
  {
    secrets: [openaiApiKey],
    timeoutSeconds: 60, // 1 minute timeout is sufficient for 6 questions
    memory: '512MiB' // Reduced memory since we're only generating 6 questions
  },
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
        res.status(401).json({ error: 'Missing or invalid Authorization header' });
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

      const result = await generateQuestionsLogic();
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
 * - gameDocumentRef: (Optional) Game document ID/path to update player document
 * - playerDocumentId: (Optional) Player document ID in the players subcollection
 * - playerEmail: (Optional) Player email for validation/logging
 * 
 * Returns:
 * - imageUrl: URL of the generated image stored in Firebase Storage
 * - updated: (If optional params provided) Whether the Firestore document was updated
 */
exports.generateCharacterPortrait = onCall(
  { secrets: [nanobananaApiKey, slackApiKey] },
  async (request) => {
    try {
      const {
        email,
        questionsAndAnswers,
        gameDocumentRef,
        playerDocumentId,
        playerEmail,
      } = request.data;

      // Validate required input
      if (!email || !questionsAndAnswers) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'email and questionsAndAnswers are required'
        );
      }

      // Check if optional Firestore update parameters are provided
      const shouldUpdateFirestore = gameDocumentRef && playerDocumentId;

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
      const ai = new GoogleGenAI({ apiKey: nanobananaApiKey.value() });

      const styles = [
        'The Simpsons',
        'Adventure Time',
        'Family Guy',
        'Studio Ghibli',
        'Anime',
        'Russian/Soviet',
        'Rubber hose',
        'Pixar',
        'Kawaii',
        'Cyberpunk',
        'My Little Pony',
        'Comic book',
        'Lego (3D)',
        'Minecraft',
        'Steamboat Willie',
        'The Flintstones',
        'The Jetsons',
        'The Powerpuff Girls',
        'The Ren & Stimpy Show',
        'The Smurfs',
        'Hey Arthur',
        'Scooby Doo',
      ];

      const style = styles[Math.floor(Math.random() * styles.length)];

      // Create prompt incorporating the questions and answers
      const prompt = `Create a cartoon character portrait that incorporates the following preferences and answers:
${questionsAndAnswers}

The character should visually represent these preferences. For example, if they prefer coffee over tea, show them holding a coffee.

Create the image as a square, 500x500 pixels. It should be in ${style} style.

The logo of the Dreamflow is at https://firebasestorage.googleapis.com/v0/b/xni75w9l4qcdp0p0xnbergczhoxgud.firebasestorage.app/o/df_logo.png?alt=media&token=dae9f105-8410-4338-b073-22c5fb160695. 
Consider incorporating the logo into the image, such as on the character's shirt or mug. If you do, try to make the logo as accurate as possible.
`;

      console.log('Generating image with Nano Banana...');

      const geminiResponse = await ai.models.generateContent({
        model: 'gemini-3-pro-image-preview',
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

      // Step 5: Update Firestore if optional parameters are provided
      let firestoreUpdated = false;
      if (shouldUpdateFirestore) {
        try {
          const playerRef = admin
            .firestore()
            .collection('games')
            .doc(gameDocumentRef)
            .collection('players')
            .doc(playerDocumentId);

          await playerRef.update({
            image: imageUrl,
          });

          firestoreUpdated = true;
          console.log(
            `Updated player document: games/${gameDocumentRef}/players/${playerDocumentId}`
          );
        } catch (firestoreError) {
          console.error('Error updating Firestore document:', firestoreError);
          // Don't throw error - image was generated successfully, just log the Firestore error
          // This allows the function to still return the imageUrl even if Firestore update fails
        }
      }

      const result = {
        success: true,
        imageUrl: imageUrl,
      };

      if (shouldUpdateFirestore) {
        result.updated = firestoreUpdated;
      }

      return result;

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
