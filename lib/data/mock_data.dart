class MockData {
  static final List<Map<String, dynamic>> jobs = [
    {
      'id': '1',
      'title': 'Software Engineer',
      'company': 'Tech Solutions Inc.',
      'location': 'Bengaluru, KA',
      'salary': '₹12,00,000/yr',
      'type': 'Full-time',
      'posted': '2 days ago',
      'applicants': 15,
      'level': 'Mid-Senior level',
      'description': 'We are looking for a Software Engineer to join our core team. You will be responsible for developing scalable backend services and engaging user interfaces.',
      'requirements': [
        '3+ years of experience in full-stack development.',
        'Proficiency in HTML, CSS, JavaScript, and C#.',
        'Strong problem-solving skills.',
      ],
    },
    {
      'id': '2',
      'title': 'Delivery Executive',
      'company': 'QuickCart Logistics',
      'location': 'Bengaluru, KA',
      'salary': '₹20,000/mo',
      'type': 'Part-time',
      'posted': '1 day ago',
      'applicants': 42,
      'level': 'Entry level',
      'description': 'Deliver groceries to customers quickly and safely.',
      'requirements': [
        'Must have a valid driving license and two-wheeler.',
        'Smartphone with active internet connection.',
      ],
    },
    {
      'id': '3',
      'title': 'Store Manager',
      'company': 'Local Grocers',
      'location': 'Bengaluru, KA',
      'salary': '₹6,00,000/yr',
      'type': 'Full-time',
      'posted': '5 days ago',
      'applicants': 8,
      'level': 'Mid level',
      'description': 'Manage daily operations of the grocery store, manage staff, and ensure customer satisfaction.',
      'requirements': [
        '2+ years of retail management experience.',
        'Good communication and leadership skills.',
      ],
    },
  ];

  static final List<Map<String, dynamic>> offers = [
    {
      'id': '1',
      'title': 'State Bank of India',
      'subtitle': 'Education Loan at 8%',
      'description': 'Zero processing fee',
      'type': 'Loans',
      'action': 'Apply',
    },
    {
      'id': '2',
      'title': 'Excel Coaching',
      'subtitle': '30% OFF IAS Batch',
      'description': 'Nearby',
      'type': 'Education',
      'action': 'Claim',
    },
    {
      'id': '3',
      'title': 'City Gym',
      'subtitle': '1 Month Free',
      'description': 'Nearby',
      'type': 'Services',
      'action': 'Claim',
    },
  ];

  static final Map<String, dynamic> testDetails = {
    'title': 'IAS Prelims Mock Test 1',
    'subtitle': 'General Studies Paper I',
    'questions': 100,
    'minutes': 120,
    'marks': 200,
    'negative_marking': '-0.66',
    'instructions': [
      'The test contains multiple-choice questions with 4 options each.',
      '1/3rd of the marks assigned to a question will be deducted for wrong answers.',
      'Ensure you have a stable internet connection.',
      'Do not switch tabs while taking the test.',
    ],
  };

  static final List<Map<String, dynamic>> testQuestions = [
    {
      'id': '1',
      'questionText': 'Consider the following statements regarding the \'National Hydrogen Mission\':\n\n1. It aims to make India a global hub for the production and export of green hydrogen.\n2. It proposes to mandate the use of green hydrogen in fertilizer and refining industries.\n\nWhich of the statements given above is/are correct?',
      'options': [
        '1 only',
        '2 only',
        'Both 1 and 2',
        'Neither 1 nor 2',
      ],
      'correctIndex': 2,
    }
  ];
}
