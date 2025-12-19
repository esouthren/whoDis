enum QuestionDifficulty { hard, medium, easy }

class Question {
  final String text;
  final QuestionDifficulty difficulty;

  const Question(this.text, this.difficulty);
}

const List<Question> allQuestions = [
// Hard questions (abstract / subtle identifiers)
Question('What time did you wake up this morning?', QuestionDifficulty.hard),
Question('What was the first thing you ate today?', QuestionDifficulty.hard),
Question('What is your favorite color?', QuestionDifficulty.hard),
Question('What is the last movie you watched?', QuestionDifficulty.hard),
Question('What’s a phrase you use often?', QuestionDifficulty.hard),
Question('What’s your favorite day of the week?', QuestionDifficulty.hard),
Question('Do you prefer mornings or nights?', QuestionDifficulty.hard),
Question('What kind of weather do you like most?', QuestionDifficulty.hard),
Question('What is something you’re currently learning?', QuestionDifficulty.hard),
Question('What type of phone do you use?', QuestionDifficulty.hard),
Question('What’s your favorite type of drink?', QuestionDifficulty.hard),
Question('What app do you open first most mornings?', QuestionDifficulty.hard),
Question('What is one song stuck in your head recently?', QuestionDifficulty.hard),
Question('What’s a TV show you’ve recently started?', QuestionDifficulty.hard),
Question('Do you prefer cats or dogs?', QuestionDifficulty.hard),
Question('Do you wear glasses or contacts?', QuestionDifficulty.hard),
Question('What’s a small daily habit you enjoy?', QuestionDifficulty.hard),
Question('Do you prefer coffee or tea?', QuestionDifficulty.hard),
Question('What’s a snack you always buy?', QuestionDifficulty.hard),
Question('What kind of shoes are you wearing today?', QuestionDifficulty.hard),
Question('What is your favourite candy/sweet?', QuestionDifficulty.hard),
Question('What movie is in your top 5?', QuestionDifficulty.hard),
Question('What are you trying to do more of right now?', QuestionDifficulty.hard),
Question('What’s a smell you really like?', QuestionDifficulty.hard),
Question('What’s your go-to breakfast item?', QuestionDifficulty.hard),
Question('What’s your favorite emoji to use?', QuestionDifficulty.hard),
Question('What’s the last photo you took?', QuestionDifficulty.hard),
Question('Do you prefer texting or calling?', QuestionDifficulty.hard),
Question('What kind of bag do you usually carry?', QuestionDifficulty.hard),
Question('What’s the first thing you do when you log off for the day?', QuestionDifficulty.hard),
Question('Do you use dark mode or light mode?', QuestionDifficulty.hard),
Question('What’s your favorite kind of dessert?', QuestionDifficulty.hard),
Question('What’s a quote you like?', QuestionDifficulty.hard),
Question('Do you prefer baths or showers?', QuestionDifficulty.hard),
Question('What’s a smell that reminds you of childhood?', QuestionDifficulty.hard),
Question('What’s your go-to playlist or music mood?', QuestionDifficulty.hard),
Question('What’s your favorite fruit?', QuestionDifficulty.hard),
Question('Do you like spicy food?', QuestionDifficulty.hard),
Question('What’s a word you use too often?', QuestionDifficulty.hard),
Question('Do you prefer reading or watching?', QuestionDifficulty.hard),
Question('What’s your favorite type of soup?', QuestionDifficulty.hard),
Question('What’s the last thing you searched online?', QuestionDifficulty.hard),
Question('Do you prefer writing by hand or typing?', QuestionDifficulty.hard),
Question('What’s your default web browser?', QuestionDifficulty.hard),
Question('How many alarms do you usually set?', QuestionDifficulty.hard),
Question('What’s your current phone wallpaper vibe (photo, abstract, quote)?', QuestionDifficulty.hard),
Question('Do you keep inbox zero or let emails pile up?', QuestionDifficulty.hard),
Question('What keyboard layout do you use most (QWERTY, AZERTY, etc.)?', QuestionDifficulty.hard),
Question('Tabs person or windows person on your computer?', QuestionDifficulty.hard),
Question('What’s your preferred note-taking style (bullets, outlines, freeform)?', QuestionDifficulty.hard),
Question('What’s your go-to pen type (gel, ballpoint, fountain)?', QuestionDifficulty.hard),
Question('What’s your favorite candle or home scent?', QuestionDifficulty.hard),
Question('What kind of water bottle do you carry most (metal, plastic, smart)?', QuestionDifficulty.hard),
Question('Do you use read receipts for messages?', QuestionDifficulty.hard),
Question('What’s your most-used keyboard shortcut?', QuestionDifficulty.hard),
Question('Do you prefer paper books, e-readers, or audiobooks?', QuestionDifficulty.hard),
Question('What’s your favorite pancake or waffle topping?', QuestionDifficulty.hard),
Question('How do you organize your phone apps (folders, by color, search)?', QuestionDifficulty.hard),
Question('Do you prefer silent, vibrate, or sound on your phone?', QuestionDifficulty.hard),
Question('What’s your favorite mug style (large ceramic, enamel, travel)?', QuestionDifficulty.hard),
Question('What kind of playlists do you make (mood, genre, decade)?', QuestionDifficulty.hard),
Question('Are you a night shower or morning shower person?', QuestionDifficulty.hard),

// Medium questions (moderately identifying)
Question('What is your favorite hobby?', QuestionDifficulty.medium),
Question('What is your favorite food?', QuestionDifficulty.medium),
Question('What type of music do you listen to?', QuestionDifficulty.medium),
Question('What did you do last weekend?', QuestionDifficulty.medium),
Question('What’s your favorite movie genre?', QuestionDifficulty.medium),
Question('What is your favorite holiday destination?', QuestionDifficulty.medium),
Question('What is your favorite sport or physical activity?', QuestionDifficulty.medium),
Question('What kind of shows do you usually watch?', QuestionDifficulty.medium),
Question('What is a restaurant you like going to?', QuestionDifficulty.medium),
Question('What kind of pet would you like to have?', QuestionDifficulty.medium),
Question('Who is a celebrity you admire?', QuestionDifficulty.medium),
Question('What’s your go-to comfort meal?', QuestionDifficulty.medium),
Question('What’s your favorite season of the year?', QuestionDifficulty.medium),
Question('What kind of podcasts do you enjoy?', QuestionDifficulty.medium),
Question('What’s your favorite ice cream flavor?', QuestionDifficulty.medium),
Question('Do you prefer beaches or mountains?', QuestionDifficulty.medium),
Question('What’s a brand you use a lot?', QuestionDifficulty.medium),
Question('What’s your favorite way to relax?', QuestionDifficulty.medium),
Question('What’s a type of cuisine you love?', QuestionDifficulty.medium),
Question('What’s the last concert or event you went to?', QuestionDifficulty.medium),
Question('What is the most impressive meal you can cook?', QuestionDifficulty.medium),
Question('You have \$10,000 to spend in any shop. Where do you go?', QuestionDifficulty.medium),
Question('What’s your favorite childhood TV show?', QuestionDifficulty.medium),
Question('What’s your dream vacation spot?', QuestionDifficulty.medium),
Question('What’s your favorite book or author?', QuestionDifficulty.medium),
Question('What’s a skill you wish you had?', QuestionDifficulty.medium),
Question('What’s a hobby you’ve dropped but miss?', QuestionDifficulty.medium),
Question('What’s a place you’d love to live in?', QuestionDifficulty.medium),
Question('What’s your favorite board or card game?', QuestionDifficulty.medium),
Question('Who is your favorite musician or band?', QuestionDifficulty.medium),
Question('What’s your favorite comfort TV show?', QuestionDifficulty.medium),
Question('What’s a food you could eat every day?', QuestionDifficulty.medium),
Question('Do you prefer sweet or savory foods?', QuestionDifficulty.medium),
Question('What’s your go-to coffee or tea order?', QuestionDifficulty.medium),
Question('What’s a new activity you want to try?', QuestionDifficulty.medium),
Question('What’s your favorite childhood meal?', QuestionDifficulty.medium),
Question('Who inspires you creatively?', QuestionDifficulty.medium),
Question('What’s your favorite thing about weekends?', QuestionDifficulty.medium),
Question('Do you prefer planning or being spontaneous?', QuestionDifficulty.medium),
Question('What’s your favorite type of art or design?', QuestionDifficulty.medium),
Question('What’s your favorite social media platform?', QuestionDifficulty.medium),
Question('What’s a product or gadget you can’t live without?', QuestionDifficulty.medium),
Question('Which fitness or health app do you use most?', QuestionDifficulty.medium),
Question('What game platform do you use most (Switch, PlayStation, Xbox, PC, mobile)?', QuestionDifficulty.medium),
Question('What newsletter or blog do you read regularly?', QuestionDifficulty.medium),
Question('Which grocery store category do you prefer (discount, premium, organic)?', QuestionDifficulty.medium),
Question('What coding language or creative tool do you reach for first?', QuestionDifficulty.medium),
Question('Which airline do you fly most often (if any)?', QuestionDifficulty.medium),
Question('What’s your go-to rideshare or transport app?', QuestionDifficulty.medium),
Question('Which smartwatch or tracker brand do you wear, if any?', QuestionDifficulty.medium),
Question('What style of cuisine do you cook most at home?', QuestionDifficulty.medium),
Question('Which streaming music service do you use?', QuestionDifficulty.medium),
Question('What type of gym or class do you attend (strength, yoga, spin, none)?', QuestionDifficulty.medium),
Question('Which browser extensions can you not live without?', QuestionDifficulty.medium),
Question('What publication do you trust for tech or business news?', QuestionDifficulty.medium),
Question('Which charity or cause do you tend to support?', QuestionDifficulty.medium),
Question('What type of camera do you use most (phone, mirrorless, DSLR, film)?', QuestionDifficulty.medium),
Question('Which operating system do you use for work primarily?', QuestionDifficulty.medium),
Question('What brand of headphones/earbuds do you prefer?', QuestionDifficulty.medium),
Question('Which map app do you default to?', QuestionDifficulty.medium),
Question('What type of backpack or everyday bag brand do you favor?', QuestionDifficulty.medium),
Question('Which food delivery platform do you use most?', QuestionDifficulty.medium),
Question('What is the furthest distance you have ever run in one go?', QuestionDifficulty.medium),


// Easy questions (strong identifiers)
Question('What country do you live in?', QuestionDifficulty.easy),
Question('What is the last country you visited that was not your current location?', QuestionDifficulty.easy),
Question('What city were you born in?', QuestionDifficulty.easy),
Question('What is your job or field of study?', QuestionDifficulty.easy),
Question('What language do you speak most often?', QuestionDifficulty.easy),
Question('What’s the name of your hometown?', QuestionDifficulty.easy),
Question('What time zone are you in?', QuestionDifficulty.easy),
Question('What’s your favorite sports team?', QuestionDifficulty.easy),
Question('What is your favorite local restaurant or café?', QuestionDifficulty.easy),
Question('What is your favorite clothing brand?', QuestionDifficulty.easy),
Question('What kind of car (or transport) do you use most often?', QuestionDifficulty.easy),
Question('What’s a big city you’ve lived in?', QuestionDifficulty.easy),
Question('What’s a nearby landmark or attraction?', QuestionDifficulty.easy),
Question('What’s the name of your favorite teacher or mentor?', QuestionDifficulty.easy),
Question('What kind of house or apartment do you live in?', QuestionDifficulty.easy),
Question('What was your high school mascot or symbol?', QuestionDifficulty.easy),
Question('What’s a unique hobby or talent you have?', QuestionDifficulty.easy),
Question('What’s your favorite local activity?', QuestionDifficulty.easy),
Question('What’s the name of your pet (if any)?', QuestionDifficulty.easy),
Question('What neighborhood do you live in?', QuestionDifficulty.easy),
Question('If you went, where did you go to university?', QuestionDifficulty.easy),
Question('What’s your current city?', QuestionDifficulty.easy),
Question('What’s your country’s national dish?', QuestionDifficulty.easy),
Question('What’s a local phrase or slang word you often use?', QuestionDifficulty.easy),
Question('Where do you usually go for groceries?', QuestionDifficulty.easy),
Question('What public transport do you take most often?', QuestionDifficulty.easy),
Question('What local event or festival do you enjoy?', QuestionDifficulty.easy),
Question('What’s the biggest nearby city to you?', QuestionDifficulty.easy),
Question('What time do you like to start working?', QuestionDifficulty.easy),
Question('What’s a local park or beach you visit often?', QuestionDifficulty.easy),
Question('What kind of climate do you live in?', QuestionDifficulty.easy),
Question('What was your first ever job?', QuestionDifficulty.easy),
Question('Where do most of your family members live?', QuestionDifficulty.easy),
Question('What kind of area do you live in (urban, suburban, rural)?', QuestionDifficulty.easy),
Question('Where was your first school?', QuestionDifficulty.easy),
Question('What was your first pet’s name?', QuestionDifficulty.easy),
Question('What’s your favorite nearby coffee shop?', QuestionDifficulty.easy),
Question('Which airport do you usually fly out of (airport code)?', QuestionDifficulty.easy),
Question('What neighborhood are you most often in on weekends?', QuestionDifficulty.easy),
Question('Who is your current mobile carrier?', QuestionDifficulty.easy),
Question('What year did you graduate high school?', QuestionDifficulty.easy),
Question('Which university or bootcamp program did you last complete?', QuestionDifficulty.easy),
Question('What’s your usual commute mode (train, bus, bike, drive, walk)?', QuestionDifficulty.easy),
Question('Which gym chain or studio are you a member of, if any?', QuestionDifficulty.easy),
Question('What is your professional certification (if any)?', QuestionDifficulty.easy),
Question('Which coworking space or office campus do you use most?', QuestionDifficulty.easy),
Question('What’s the primary language of your workplace?', QuestionDifficulty.easy),
Question('Which major sports club (local or national) do you follow most closely?', QuestionDifficulty.easy),
Question('Which grocery chain do you visit most often?', QuestionDifficulty.easy),
Question('What’s the make and model of your daily computer?', QuestionDifficulty.easy),
Question('Which local radio station or regional news outlet do you follow?', QuestionDifficulty.easy),
Question('What’s the first big concert venue you think of near you?', QuestionDifficulty.easy),
Question('Which national holiday do you celebrate that’s specific to your country/region?', QuestionDifficulty.easy),
Question('What’s the nearest major university to where you live now?', QuestionDifficulty.easy),
Question('When did you first join FlutterFlow (month and year)?', QuestionDifficulty.easy),

];

List<Question> getRandomizedQuestionsForRound() {
  final hard = allQuestions.where((q) => q.difficulty == QuestionDifficulty.hard).toList()..shuffle();
  final medium = allQuestions.where((q) => q.difficulty == QuestionDifficulty.medium).toList()..shuffle();
  final easy = allQuestions.where((q) => q.difficulty == QuestionDifficulty.easy).toList()..shuffle();
  
  return [
    ...hard.take(2),
    ...medium.take(3),
    ...easy.take(1),
  ];
}

List<int> getRandomizedQuestionIndices() {
  final hardIndices = <int>[];
  final mediumIndices = <int>[];
  final easyIndices = <int>[];
  
  for (int i = 0; i < allQuestions.length; i++) {
    switch (allQuestions[i].difficulty) {
      case QuestionDifficulty.hard:
        hardIndices.add(i);
        break;
      case QuestionDifficulty.medium:
        mediumIndices.add(i);
        break;
      case QuestionDifficulty.easy:
        easyIndices.add(i);
        break;
    }
  }
  
  hardIndices.shuffle();
  mediumIndices.shuffle();
  easyIndices.shuffle();
  
  return [
    ...hardIndices.take(2),
    ...mediumIndices.take(3),
    ...easyIndices.take(1),
  ];
}
