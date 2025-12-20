enum QuestionDifficulty { hard, medium, easy }

class Question {
  final String text;
  final QuestionDifficulty difficulty;

  const Question(this.text, this.difficulty);
}
