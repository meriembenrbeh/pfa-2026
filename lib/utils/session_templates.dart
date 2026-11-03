class SessionTemplates {
  static final Map<String, String> _templates = {
    // Mathématiques
    'math': 'Cours de mathématiques couvrant les concepts fondamentaux avec des exercices pratiques et des exemples concrets.',
    'maths': 'Cours de mathématiques couvrant les concepts fondamentaux avec des exercices pratiques et des exemples concrets.',
    'mathématiques': 'Cours de mathématiques couvrant les concepts fondamentaux avec des exercices pratiques et des exemples concrets.',
    'algèbre': 'Introduction à l\'algèbre avec résolution d\'équations et manipulation d\'expressions algébriques.',
    'géométrie': 'Étude des formes, des angles et des propriétés géométriques avec des constructions pratiques.',
    'dérivées': 'Comprendre les dérivées et leurs applications dans l\'analyse de fonctions.',
    'intégrales': 'Introduction au calcul intégral et ses applications en sciences et ingénierie.',
    
    // Physique
    'physique': 'Cours de physique expliquant les lois fondamentales de la nature avec des expériences.',
    'mécanique': 'Étude du mouvement et des forces qui régissent les objets.',
    'électricité': 'Introduction aux circuits électriques et aux phénomènes électromagnétiques.',
    'optique': 'Comprendre la lumière, les lentilles et les instruments optiques.',
    
    // Chimie
    'chimie': 'Cours de chimie couvrant la structure de la matière et les réactions chimiques.',
    'organique': 'Introduction à la chimie organique et ses composés.',
    'inorganique': 'Étude des éléments chimiques et de leurs composés.',
    
    // Français
    'français': 'Amélioration de la langue française : grammaire, vocabulaire et expression écrite.',
    'grammaire': 'Règles de grammaire française avec exercices pratiques.',
    'littérature': 'Analyse d\'œuvres littéraires françaises et techniques de commentaire.',
    'orthographe': 'Maîtrise de l\'orthographe française et règles d\'accord.',
    
    // Anglais
    'anglais': 'Cours d\'anglais pour améliorer la compréhension et l\'expression orale et écrite.',
    'english': 'English course focusing on grammar, vocabulary, and communication skills.',
    'toefl': 'Préparation au test TOEFL avec stratégies et exercices.',
    'ielts': 'Préparation à l\'examen IELTS pour atteindre votre objectif de score.',
    
    // Histoire
    'histoire': 'Exploration des événements historiques majeurs et leur impact sur le monde actuel.',
    'géographie': 'Étude des territoires, des populations et des enjeux géopolitiques.',
    
    // Informatique
    'informatique': 'Introduction à l\'informatique et aux technologies de l\'information.',
    'programmation': 'Apprentissage des bases de la programmation et algorithmes.',
    'python': 'Cours de programmation Python pour débutants et intermédiaires.',
    'java': 'Développement d\'applications Java avec concepts orientés objet.',
    'web': 'Création de sites web avec HTML, CSS et JavaScript.',
    
    // Sciences
    'biologie': 'Étude des organismes vivants et des processus biologiques.',
    'svt': 'Sciences de la vie et de la terre : biologie et géologie.',
    'science': 'Introduction aux méthodes scientifiques et aux principes fondamentaux.',
  };

  static String? getSuggestedDescription(String subject) {
    final lowerSubject = subject.toLowerCase();
    
    for (final entry in _templates.entries) {
      if (lowerSubject.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return null;
  }
}
