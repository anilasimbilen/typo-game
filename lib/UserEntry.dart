class UserEntry {

  UserEntry({this.name, this.text, this.score});
  String name;
  String text;
  int score;
  factory UserEntry.fromJson(Map<String, dynamic> parsedJson) {
    return UserEntry(name: parsedJson["userName"], text: parsedJson["text"], score: parsedJson["score"]);
  }
  @override
  String toString() {
    return "İsim: $name  Skor: $score";
  }
}