import 'dart:math';

class WordEntry {
  final String word;
  final String category;
  final String hint;

  const WordEntry({
    required this.word,
    required this.category,
    required this.hint,
  });
}

class WordBank {
  static final Random _random = Random();

  /// Curated 5-letter words with student, career, tech, and everyday vocabulary
  static const List<WordEntry> targetWords = [
    WordEntry(word: 'FOCUS', category: 'Mindset', hint: 'The center of interest or activity; intense concentration.'),
    WordEntry(word: 'LOGIC', category: 'Thinking', hint: 'Reasoning conducted or assessed according to strict principles.'),
    WordEntry(word: 'BRAIN', category: 'Mind', hint: 'The organ of thought, memory, and cognitive control.'),
    WordEntry(word: 'LEARN', category: 'Growth', hint: 'Acquiring knowledge or skills through study or experience.'),
    WordEntry(word: 'SKILL', category: 'Career', hint: 'The ability to do something well, gained through practice.'),
    WordEntry(word: 'SOLVE', category: 'Problem', hint: 'Find an answer to, explanation for, or means of handling a problem.'),
    WordEntry(word: 'BUILD', category: 'Creation', hint: 'Construct something by putting parts or materials together.'),
    WordEntry(word: 'SMART', category: 'Mindset', hint: 'Showing quick-witted intelligence or thoughtful design.'),
    WordEntry(word: 'QUERY', category: 'Tech', hint: 'A question or request for information from a database.'),
    WordEntry(word: 'STACK', category: 'Tech', hint: 'A collection of technologies used together, or a LIFO data structure.'),
    WordEntry(word: 'INDEX', category: 'Tech', hint: 'An indicator, sign, or database pointer for fast retrieval.'),
    WordEntry(word: 'VALUE', category: 'Career', hint: 'The regard that something is held to deserve; importance or worth.'),
    WordEntry(word: 'POWER', category: 'Science', hint: 'The capacity or ability to direct or influence behavior or work.'),
    WordEntry(word: 'GOALS', category: 'Career', hint: 'The objects of a person\'s ambition or desired results.'),
    WordEntry(word: 'GUIDE', category: 'Career', hint: 'A person or principle advising or showing the way forward.'),
    WordEntry(word: 'CLOUD', category: 'Tech', hint: 'Network of remote servers hosted on the Internet to store data.'),
    WordEntry(word: 'DRIVE', category: 'Mindset', hint: 'An innate motivation or determined urge to succeed.'),
    WordEntry(word: 'GRAPH', category: 'Math', hint: 'A diagram showing the relation between variable quantities.'),
    WordEntry(word: 'MODEL', category: 'Tech', hint: 'A representation of a system used to explain phenomena or run AI.'),
    WordEntry(word: 'STUDY', category: 'Growth', hint: 'Devotion of time and attention to acquiring knowledge.'),
    WordEntry(word: 'THINK', category: 'Mind', hint: 'Direct one\'s mind toward someone or something.'),
    WordEntry(word: 'REACT', category: 'Tech', hint: 'Respond to an action or stimulus; also a popular UI framework.'),
    WordEntry(word: 'SCALE', category: 'Growth', hint: 'Grow or expand proportionally to meet higher demand.'),
    WordEntry(word: 'ROUTE', category: 'Tech', hint: 'A way or course taken in getting from starting point to destination.'),
    WordEntry(word: 'SCORE', category: 'Aptitude', hint: 'The number of points or goals achieved in a game or exam.'),
    WordEntry(word: 'TESTS', category: 'Aptitude', hint: 'Procedures intended to establish the quality or performance of something.'),
    WordEntry(word: 'PIVOT', category: 'Career', hint: 'Shift strategy or direction while keeping the core foundation.'),
    WordEntry(word: 'CHART', category: 'Data', hint: 'A sheet of information in the form of a table, graph, or diagram.'),
    WordEntry(word: 'SOLAR', category: 'Science', hint: 'Relating to or determined by the sun and renewable energy.'),
    WordEntry(word: 'SPACE', category: 'Science', hint: 'A continuous area or expanse which is free or unoccupied.'),
    WordEntry(word: 'QUEST', category: 'Growth', hint: 'A long or arduous search for something valuable or meaningful.'),
    WordEntry(word: 'TRACK', category: 'Career', hint: 'Follow the trail or progress of; a designated career path.'),
    WordEntry(word: 'CRAFT', category: 'Skill', hint: 'An activity involving skill in making things especially by hand/code.'),
    WordEntry(word: 'ALERT', category: 'Mindset', hint: 'Quick to notice any unusual and potentially dangerous circumstances.'),
    WordEntry(word: 'FORCE', category: 'Physics', hint: 'Strength or energy as an attribute of physical action or movement.'),
    WordEntry(word: 'SPEED', category: 'Aptitude', hint: 'The rate at which someone or something is able to move or operate.'),
    WordEntry(word: 'PULSE', category: 'Biology', hint: 'A rhythmical throbbing of the arteries as blood is propelled.'),
    WordEntry(word: 'SHARP', category: 'Mindset', hint: 'Having or showing quick intelligence or discernment.'),
    WordEntry(word: 'SCOPE', category: 'Career', hint: 'The extent of the area or subject matter that something deals with.'),
    WordEntry(word: 'CACHE', category: 'Tech', hint: 'A high-speed data storage layer which stores a subset of data.'),
    WordEntry(word: 'PIXEL', category: 'Tech', hint: 'A minute area of illumination on a display screen.'),
    WordEntry(word: 'DEBUG', category: 'Tech', hint: 'Identify and remove errors from computer hardware or software.'),
    WordEntry(word: 'PRIME', category: 'Math', hint: 'A number divisible only by itself and 1; of the best quality.'),
    WordEntry(word: 'RATIO', category: 'Math', hint: 'The quantitative relation between two amounts.'),
    WordEntry(word: 'POINT', category: 'Math', hint: 'A precise location or element in a given mathematical space.'),
    WordEntry(word: 'TREND', category: 'Career', hint: 'A general direction in which something is developing or changing.'),
    WordEntry(word: 'SPARK', category: 'Mindset', hint: 'Provide the stimulus for; a small fiery inspiration.'),
    WordEntry(word: 'RESET', category: 'Mindset', hint: 'Set again or differently; clear state and begin afresh.'),
    WordEntry(word: 'MERIT', category: 'Career', hint: 'The quality of being particularly good or worthy of praise.'),
    WordEntry(word: 'LEADR', category: 'Career', hint: 'One who guides or inspires others toward a common mission.'),
    WordEntry(word: 'DRAFT', category: 'Skill', hint: 'A preliminary version of a piece of writing or project plan.'),
    WordEntry(word: 'PHASE', category: 'Project', hint: 'A distinct period or stage in a process of change or development.'),
    WordEntry(word: 'FIELD', category: 'Career', hint: 'A particular branch of study or sphere of activity.'),
    WordEntry(word: 'AUDIT', category: 'Finance', hint: 'An official inspection of an individual\'s or organization\'s accounts.'),
    WordEntry(word: 'RANGE', category: 'Math', hint: 'The area of variation between upper and lower limits on a scale.'),
    WordEntry(word: 'VALID', category: 'Logic', hint: 'Having a sound basis in logic or fact; reasonable or cogent.'),
    WordEntry(word: 'VOICE', category: 'Career', hint: 'An agency by which a point of view is expressed or represented.'),
    WordEntry(word: 'BRIEF', category: 'Work', hint: 'Concise in use of words; a set of instructions given to a person.'),
    WordEntry(word: 'CLIMB', category: 'Growth', hint: 'Ascend or go up; make progress upwards in one\'s career.'),
    WordEntry(word: 'HABIT', category: 'Growth', hint: 'A settled or regular tendency or practice, especially hard to give up.'),
  ];

  /// Get a random word guaranteeing it's not the same as [excludeWord]
  static WordEntry getRandomWord({String? excludeWord}) {
    List<WordEntry> candidates = targetWords;
    if (excludeWord != null && candidates.length > 1) {
      candidates = candidates.where((w) => w.word != excludeWord.toUpperCase()).toList();
    }
    return candidates[_random.nextInt(candidates.length)];
  }

  /// Check if a guess is a valid 5-letter word
  static bool isValidGuess(String guess) {
    if (guess.length != 5) return false;
    // Any alphabetic 5-letter word is accepted for student guessing freedom
    return RegExp(r'^[A-Z]{5}$').hasMatch(guess.toUpperCase());
  }
}
