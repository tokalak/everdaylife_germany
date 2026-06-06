import Foundation

/// Einbürgerungstest practice types + question bank (P6-R3).
///
/// The official "Leben in Deutschland" / Einbürgerungstest draws from a
/// **public-domain federal catalogue** of ~300 general questions plus per-state
/// question sets. The real exam is **33 questions**; passing needs **17 correct**.
///
/// The question content is **data, not xcstrings** — a 300-question bank (each
/// with a prompt + 4 options × 2 languages) would bloat the string catalog and
/// is not UI chrome. It lives here as a versioned Swift array. The exam is in
/// German, so each question carries the German text plus a faithful English
/// translation for comprehension only (the official test is German-only).

/// A short German + English pair. The German is the source-of-truth wording; the
/// English is a comprehension aid.
struct BilingualText: Equatable {
    let de: String
    let en: String
}

/// One multiple-choice question. Exactly 4 options; `answerIndex` is the 0-based
/// index of the correct option.
struct EinbuergerungstestQuestion: Identifiable, Equatable {
    let id: Int
    let prompt: BilingualText
    let options: [BilingualText]
    let answerIndex: Int
}

/// The computed result of a scored round.
struct EinbuergerungstestResult: Equatable {
    /// Correctly answered questions.
    let correct: Int
    /// Questions in the round.
    let total: Int
    /// Correct answers needed to pass this round (pass mark scaled to the round
    /// size from the official 17-of-33 ratio).
    let requiredCorrect: Int
    /// Whether the round was passed (`correct >= requiredCorrect`).
    let passed: Bool
}

/// Versioned exam configuration + question bank (X-06 / AGENTS: content isolated
/// from views and logic, so it can grow without touching the engine or UI).
enum EinbuergerungstestBank {

    /// Questions per official exam.
    /// Re-verify against the current BAMF rules periodically (OQ-1).
    static let examQuestionCount = 33

    /// Correct answers needed to pass the official 33-question exam.
    /// Re-verify against the current BAMF rules periodically (OQ-1).
    static let passMark = 17

    /// Curated practice questions.
    ///
    /// **This is a representative subset (~30 questions) of the official
    /// public-domain catalogue**, transcribed accurately (German prompt + 4
    /// German options + the correct index, with faithful English translations).
    /// The full ~300 public-domain general questions (plus per-state sets) are to
    /// be **imported later**; the engine and UI already handle a bank of any
    /// size. Ids are unique; `answerIndex` is always 0–3.
    static let questions: [EinbuergerungstestQuestion] = [
        EinbuergerungstestQuestion(
            id: 1,
            prompt: BilingualText(
                de: "In Deutschland dürfen Menschen offen etwas gegen die Regierung sagen, weil …",
                en: "In Germany, people may openly say something against the government, because …"),
            options: [
                BilingualText(de: "hier Religionsfreiheit gilt.", en: "freedom of religion applies here."),
                BilingualText(de: "die Menschen Steuern zahlen.", en: "people pay taxes."),
                BilingualText(de: "die Menschen das Wahlrecht haben.", en: "people have the right to vote."),
                BilingualText(de: "hier Meinungsfreiheit gilt.", en: "freedom of opinion applies here."),
            ],
            answerIndex: 3),
        EinbuergerungstestQuestion(
            id: 2,
            prompt: BilingualText(
                de: "Was ist mit dem deutschen Grundgesetz nicht vereinbar?",
                en: "What is not compatible with the German constitution (Grundgesetz)?"),
            options: [
                BilingualText(de: "die Prügelstrafe", en: "corporal punishment"),
                BilingualText(de: "die Meinungsfreiheit", en: "freedom of opinion"),
                BilingualText(de: "das Wahlrecht", en: "the right to vote"),
                BilingualText(de: "die Pressefreiheit", en: "freedom of the press"),
            ],
            answerIndex: 0),
        EinbuergerungstestQuestion(
            id: 3,
            prompt: BilingualText(
                de: "Welches Recht gehört zu den Grundrechten in Deutschland?",
                en: "Which right is one of the basic rights in Germany?"),
            options: [
                BilingualText(de: "Waffenbesitz", en: "possession of weapons"),
                BilingualText(de: "Faustrecht", en: "the law of the jungle"),
                BilingualText(de: "Meinungsfreiheit", en: "freedom of opinion"),
                BilingualText(de: "Selbstjustiz", en: "vigilante justice"),
            ],
            answerIndex: 2),
        EinbuergerungstestQuestion(
            id: 4,
            prompt: BilingualText(
                de: "Wie heißt die deutsche Verfassung?",
                en: "What is the name of the German constitution?"),
            options: [
                BilingualText(de: "Volksgesetz", en: "People's Law"),
                BilingualText(de: "Bundesgesetz", en: "Federal Law"),
                BilingualText(de: "Deutsches Gesetz", en: "German Law"),
                BilingualText(de: "Grundgesetz", en: "Basic Law (Grundgesetz)"),
            ],
            answerIndex: 3),
        EinbuergerungstestQuestion(
            id: 5,
            prompt: BilingualText(
                de: "Deutschland ist ein Rechtsstaat. Was ist damit gemeint?",
                en: "Germany is a state under the rule of law. What does that mean?"),
            options: [
                BilingualText(de: "Alle Einwohner und der Staat müssen sich an die Gesetze halten.",
                              en: "All inhabitants and the state must obey the laws."),
                BilingualText(de: "Der Staat muss sich nicht an die Gesetze halten.",
                              en: "The state does not have to obey the laws."),
                BilingualText(de: "Nur Deutsche müssen die Gesetze befolgen.",
                              en: "Only Germans must obey the laws."),
                BilingualText(de: "Der Staat steht über dem Gesetz.",
                              en: "The state stands above the law."),
            ],
            answerIndex: 0),
        EinbuergerungstestQuestion(
            id: 6,
            prompt: BilingualText(
                de: "Was steht nicht im Grundgesetz von Deutschland?",
                en: "What is not in Germany's constitution?"),
            options: [
                BilingualText(de: "Die Menschenwürde ist unantastbar.", en: "Human dignity is inviolable."),
                BilingualText(de: "Alle sind vor dem Gesetz gleich.", en: "All are equal before the law."),
                BilingualText(de: "Jeder darf seine Meinung sagen.", en: "Everyone may state their opinion."),
                BilingualText(de: "Alle müssen einer Kirche angehören.", en: "Everyone must belong to a church."),
            ],
            answerIndex: 3),
        EinbuergerungstestQuestion(
            id: 7,
            prompt: BilingualText(
                de: "Wie viele Bundesländer hat die Bundesrepublik Deutschland?",
                en: "How many federal states does the Federal Republic of Germany have?"),
            options: [
                BilingualText(de: "14", en: "14"),
                BilingualText(de: "15", en: "15"),
                BilingualText(de: "16", en: "16"),
                BilingualText(de: "17", en: "17"),
            ],
            answerIndex: 2),
        EinbuergerungstestQuestion(
            id: 8,
            prompt: BilingualText(
                de: "Was ist die Hauptstadt der Bundesrepublik Deutschland?",
                en: "What is the capital of the Federal Republic of Germany?"),
            options: [
                BilingualText(de: "Bonn", en: "Bonn"),
                BilingualText(de: "Berlin", en: "Berlin"),
                BilingualText(de: "Hamburg", en: "Hamburg"),
                BilingualText(de: "Frankfurt am Main", en: "Frankfurt am Main"),
            ],
            answerIndex: 1),
        EinbuergerungstestQuestion(
            id: 9,
            prompt: BilingualText(
                de: "Wer wählt in Deutschland den Bundeskanzler / die Bundeskanzlerin?",
                en: "Who elects the Federal Chancellor in Germany?"),
            options: [
                BilingualText(de: "der Bundesrat", en: "the Bundesrat (Federal Council)"),
                BilingualText(de: "die Bundesversammlung", en: "the Federal Convention"),
                BilingualText(de: "das Volk", en: "the people"),
                BilingualText(de: "der Bundestag", en: "the Bundestag (Federal Parliament)"),
            ],
            answerIndex: 3),
        EinbuergerungstestQuestion(
            id: 10,
            prompt: BilingualText(
                de: "Wer wird vom Volk in Deutschland direkt gewählt?",
                en: "Who is directly elected by the people in Germany?"),
            options: [
                BilingualText(de: "der Bundespräsident / die Bundespräsidentin",
                              en: "the Federal President"),
                BilingualText(de: "der Bundeskanzler / die Bundeskanzlerin",
                              en: "the Federal Chancellor"),
                BilingualText(de: "der Abgeordnete / die Abgeordnete des Bundestags",
                              en: "the member of the Bundestag"),
                BilingualText(de: "der Ministerpräsident / die Ministerpräsidentin",
                              en: "the Minister-President of a state"),
            ],
            answerIndex: 2),
        EinbuergerungstestQuestion(
            id: 11,
            prompt: BilingualText(
                de: "Wie oft gibt es in Deutschland normalerweise Bundestagswahlen?",
                en: "How often are there normally Bundestag elections in Germany?"),
            options: [
                BilingualText(de: "alle drei Jahre", en: "every three years"),
                BilingualText(de: "alle vier Jahre", en: "every four years"),
                BilingualText(de: "alle fünf Jahre", en: "every five years"),
                BilingualText(de: "alle sechs Jahre", en: "every six years"),
            ],
            answerIndex: 1),
        EinbuergerungstestQuestion(
            id: 12,
            prompt: BilingualText(
                de: "Ab welchem Alter darf man in Deutschland den Bundestag wählen?",
                en: "From what age may you vote for the Bundestag in Germany?"),
            options: [
                BilingualText(de: "16", en: "16"),
                BilingualText(de: "18", en: "18"),
                BilingualText(de: "21", en: "21"),
                BilingualText(de: "23", en: "23"),
            ],
            answerIndex: 1),
        EinbuergerungstestQuestion(
            id: 13,
            prompt: BilingualText(
                de: "Welche Farben hat die Flagge der Bundesrepublik Deutschland?",
                en: "What colours does the flag of the Federal Republic of Germany have?"),
            options: [
                BilingualText(de: "schwarz-rot-gold", en: "black-red-gold"),
                BilingualText(de: "blau-weiß-rot", en: "blue-white-red"),
                BilingualText(de: "grün-rot-gelb", en: "green-red-yellow"),
                BilingualText(de: "schwarz-rot-grün", en: "black-red-green"),
            ],
            answerIndex: 0),
        EinbuergerungstestQuestion(
            id: 14,
            prompt: BilingualText(
                de: "Wann wurde die Bundesrepublik Deutschland gegründet?",
                en: "When was the Federal Republic of Germany founded?"),
            options: [
                BilingualText(de: "1939", en: "1939"),
                BilingualText(de: "1945", en: "1945"),
                BilingualText(de: "1949", en: "1949"),
                BilingualText(de: "1951", en: "1951"),
            ],
            answerIndex: 2),
        EinbuergerungstestQuestion(
            id: 15,
            prompt: BilingualText(
                de: "Was war der 8. Mai 1945?",
                en: "What was the 8th of May 1945?"),
            options: [
                BilingualText(de: "der Beginn des Zweiten Weltkriegs",
                              en: "the start of the Second World War"),
                BilingualText(de: "das Ende des Zweiten Weltkriegs in Europa",
                              en: "the end of the Second World War in Europe"),
                BilingualText(de: "der Tag der deutschen Wiedervereinigung",
                              en: "the day of German reunification"),
                BilingualText(de: "der Tag der Gründung der DDR",
                              en: "the founding day of the GDR"),
            ],
            answerIndex: 1),
        EinbuergerungstestQuestion(
            id: 16,
            prompt: BilingualText(
                de: "An welchem Tag feiert man in Deutschland die Deutsche Einheit?",
                en: "On which day is German Unity celebrated in Germany?"),
            options: [
                BilingualText(de: "9. November", en: "9 November"),
                BilingualText(de: "23. Mai", en: "23 May"),
                BilingualText(de: "3. Oktober", en: "3 October"),
                BilingualText(de: "1. Mai", en: "1 May"),
            ],
            answerIndex: 2),
        EinbuergerungstestQuestion(
            id: 17,
            prompt: BilingualText(
                de: "In welchem Jahr wurde die Mauer in Berlin gebaut?",
                en: "In which year was the Wall in Berlin built?"),
            options: [
                BilingualText(de: "1953", en: "1953"),
                BilingualText(de: "1961", en: "1961"),
                BilingualText(de: "1969", en: "1969"),
                BilingualText(de: "1989", en: "1989"),
            ],
            answerIndex: 1),
        EinbuergerungstestQuestion(
            id: 18,
            prompt: BilingualText(
                de: "Was bedeutet die Abkürzung „DDR“?",
                en: "What does the abbreviation \u{201E}DDR\u{201C} mean?"),
            options: [
                BilingualText(de: "Diktatur der Reichen", en: "Dictatorship of the Rich"),
                BilingualText(de: "Deutsche Demokratische Republik",
                              en: "German Democratic Republic"),
                BilingualText(de: "Demokratische Deutsche Republik",
                              en: "Democratic German Republic"),
                BilingualText(de: "Der Deutsche Reichstag", en: "The German Reichstag"),
            ],
            answerIndex: 1),
        EinbuergerungstestQuestion(
            id: 19,
            prompt: BilingualText(
                de: "Deutschland ist Mitglied …",
                en: "Germany is a member of …"),
            options: [
                BilingualText(de: "der NATO und der Europäischen Union (EU).",
                              en: "NATO and the European Union (EU)."),
                BilingualText(de: "nur der NATO.", en: "only NATO."),
                BilingualText(de: "nur der Europäischen Union (EU).",
                              en: "only the European Union (EU)."),
                BilingualText(de: "weder der NATO noch der EU.",
                              en: "neither NATO nor the EU."),
            ],
            answerIndex: 0),
        EinbuergerungstestQuestion(
            id: 20,
            prompt: BilingualText(
                de: "Welches Tier ist das Wappentier der Bundesrepublik Deutschland?",
                en: "Which animal is the heraldic animal of the Federal Republic of Germany?"),
            options: [
                BilingualText(de: "Löwe", en: "lion"),
                BilingualText(de: "Adler", en: "eagle"),
                BilingualText(de: "Bär", en: "bear"),
                BilingualText(de: "Pferd", en: "horse"),
            ],
            answerIndex: 1),
        EinbuergerungstestQuestion(
            id: 21,
            prompt: BilingualText(
                de: "Eine Frau in Deutschland möchte nach der Heirat ihren Geburtsnamen behalten. Kann sie das tun?",
                en: "A woman in Germany wants to keep her birth name after marriage. Can she do that?"),
            options: [
                BilingualText(de: "Nein, sie muss den Namen des Mannes annehmen.",
                              en: "No, she must take the husband's name."),
                BilingualText(de: "Nein, sie muss einen neuen Namen wählen.",
                              en: "No, she must choose a new name."),
                BilingualText(de: "Ja, sie kann ihren Geburtsnamen behalten.",
                              en: "Yes, she can keep her birth name."),
                BilingualText(de: "Ja, aber nur mit Erlaubnis des Mannes.",
                              en: "Yes, but only with the husband's permission."),
            ],
            answerIndex: 2),
        EinbuergerungstestQuestion(
            id: 22,
            prompt: BilingualText(
                de: "Wie nennt man in Deutschland die Trennung von Staat und Kirche?",
                en: "What is the separation of state and church called in Germany?"),
            options: [
                BilingualText(de: "Konfessionalismus", en: "confessionalism"),
                BilingualText(de: "Säkularisierung", en: "secularisation"),
                BilingualText(de: "Klerus", en: "clergy"),
                BilingualText(de: "Föderalismus", en: "federalism"),
            ],
            answerIndex: 1),
        EinbuergerungstestQuestion(
            id: 23,
            prompt: BilingualText(
                de: "Welche Religion hat die Kultur in Deutschland geprägt?",
                en: "Which religion has shaped the culture in Germany?"),
            options: [
                BilingualText(de: "der Hinduismus", en: "Hinduism"),
                BilingualText(de: "das Christentum", en: "Christianity"),
                BilingualText(de: "der Buddhismus", en: "Buddhism"),
                BilingualText(de: "der Islam", en: "Islam"),
            ],
            answerIndex: 1),
        EinbuergerungstestQuestion(
            id: 24,
            prompt: BilingualText(
                de: "Was darf der Staat in Deutschland nicht tun?",
                en: "What is the state not allowed to do in Germany?"),
            options: [
                BilingualText(de: "Steuern erheben", en: "levy taxes"),
                BilingualText(de: "Gesetze beschließen", en: "pass laws"),
                BilingualText(de: "eine Meinung verbieten, die ihm nicht gefällt",
                              en: "forbid an opinion it does not like"),
                BilingualText(de: "Beamte einstellen", en: "employ civil servants"),
            ],
            answerIndex: 2),
        EinbuergerungstestQuestion(
            id: 25,
            prompt: BilingualText(
                de: "Wer beschließt in Deutschland ein neues Gesetz?",
                en: "Who passes a new law in Germany?"),
            options: [
                BilingualText(de: "die Regierung", en: "the government"),
                BilingualText(de: "das Parlament", en: "the parliament"),
                BilingualText(de: "die Gerichte", en: "the courts"),
                BilingualText(de: "die Polizei", en: "the police"),
            ],
            answerIndex: 1),
        EinbuergerungstestQuestion(
            id: 26,
            prompt: BilingualText(
                de: "Wie heißt das deutsche Parlament?",
                en: "What is the German parliament called?"),
            options: [
                BilingualText(de: "Bundestag", en: "Bundestag"),
                BilingualText(de: "Bundesversammlung", en: "Federal Convention"),
                BilingualText(de: "Volkskammer", en: "People's Chamber"),
                BilingualText(de: "Senat", en: "Senate"),
            ],
            answerIndex: 0),
        EinbuergerungstestQuestion(
            id: 27,
            prompt: BilingualText(
                de: "Wer ist das Staatsoberhaupt der Bundesrepublik Deutschland?",
                en: "Who is the head of state of the Federal Republic of Germany?"),
            options: [
                BilingualText(de: "der Bundeskanzler / die Bundeskanzlerin",
                              en: "the Federal Chancellor"),
                BilingualText(de: "der Bundespräsident / die Bundespräsidentin",
                              en: "the Federal President"),
                BilingualText(de: "der Bundestagspräsident / die Bundestagspräsidentin",
                              en: "the President of the Bundestag"),
                BilingualText(de: "der Außenminister / die Außenministerin",
                              en: "the Foreign Minister"),
            ],
            answerIndex: 1),
        EinbuergerungstestQuestion(
            id: 28,
            prompt: BilingualText(
                de: "Womit finanziert der deutsche Staat die Sozialversicherung?",
                en: "How does the German state finance social insurance?"),
            options: [
                BilingualText(de: "mit Spenden", en: "with donations"),
                BilingualText(de: "mit Sozialabgaben der Bürger",
                              en: "with social contributions from citizens"),
                BilingualText(de: "mit Lottogewinnen", en: "with lottery winnings"),
                BilingualText(de: "gar nicht", en: "not at all"),
            ],
            answerIndex: 1),
        EinbuergerungstestQuestion(
            id: 29,
            prompt: BilingualText(
                de: "Welches ist ein deutsches Bundesland?",
                en: "Which of these is a German federal state?"),
            options: [
                BilingualText(de: "Elsass", en: "Alsace"),
                BilingualText(de: "Tirol", en: "Tyrol"),
                BilingualText(de: "Sachsen", en: "Saxony"),
                BilingualText(de: "Südtirol", en: "South Tyrol"),
            ],
            answerIndex: 2),
        EinbuergerungstestQuestion(
            id: 30,
            prompt: BilingualText(
                de: "Eltern in Deutschland sind verpflichtet, dass ihre Kinder in die Schule gehen. Wie nennt man das?",
                en: "Parents in Germany are obliged to send their children to school. What is this called?"),
            options: [
                BilingualText(de: "Schweigepflicht", en: "duty of confidentiality"),
                BilingualText(de: "Schulpflicht", en: "compulsory schooling"),
                BilingualText(de: "Wahlpflicht", en: "compulsory voting"),
                BilingualText(de: "Religionspflicht", en: "compulsory religion"),
            ],
            answerIndex: 1),
    ]
}
