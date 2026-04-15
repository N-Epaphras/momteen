// ignore_for_file: equal_keys_in_map

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GemmaAPI {
  static const String _modelFileName = 'gemma_model.gguf';
  File? _modelFile;
  bool _isInitialized = false;
  bool _isModelDownloaded = false;
  double _downloadProgress = 0.0;

  // Expanded offline Q&A database - 50 questions and answers
  final Map<String, String> _questionAnswers = {
    // Original questions (1-25)
    'what is teenage pregnancy':
        'Teenage pregnancy is when a girl or young woman becomes pregnant before the age of 20. It is a significant public health issue that can have social, economic, and health consequences for both the mother and the baby.',
    'how to prevent teenage pregnancy':
        'Teenage pregnancy can be prevented through comprehensive sex education, access to contraception, delaying sexual activity, and building healthy relationships. Talk to a trusted adult or healthcare provider for accurate information.',
    'what are the risks of teenage pregnancy':
        'Teenage pregnancy carries health risks like premature birth, low birth weight, and complications during pregnancy. There are also social and economic challenges including interrupted education, limited career opportunities, and increased poverty risk.',
    'how does abstinence prevent pregnancy':
        'Abstinence (not having sex) is the only 100% effective way to prevent pregnancy. Choosing to wait until you are older and in a committed relationship is a healthy and valid choice.',
    'what is contraception':
        'Contraception (birth control) includes methods like condoms, pills, IUDs, implants, and more that help prevent pregnancy when used correctly. Some also protect against sexually transmitted infections (STIs).',
    'how effective are condoms':
        'Condoms are about 85-98% effective at preventing pregnancy when used correctly every time. They also help protect against sexually transmitted infections (STIs).',
    'what is the birth control pill':
        'The birth control pill is a daily medication that contains hormones to prevent ovulation. When taken correctly, it is over 99% effective at preventing pregnancy.',
    'what is an IUD':
        'An IUD (Intrauterine Device) is a small, T-shaped device inserted into the uterus by a healthcare provider. It can prevent pregnancy for 3-10 years depending on the type, and is over 99% effective.',
    'what is the implant':
        'The implant is a small, thin rod placed under the skin of the upper arm. It releases hormones and can prevent pregnancy for up to 3 years. It is over 99% effective.',
    'what is emergency contraception':
        'Emergency contraception (morning-after pill) can be used after unprotected sex to prevent pregnancy. It is most effective when taken as soon as possible after intercourse.',
    'how do teenage pregnancies affect education':
        'Teenage pregnancy often interrupts or ends educational pursuits. Many teen mothers drop out of school due to financial constraints, lack of childcare, or health complications.',
    'what are the emotional effects of teenage pregnancy':
        'Teenage pregnancy can cause emotional stress, anxiety, depression, and feelings of shame or isolation. Support from family, friends, and healthcare providers is crucial.',
    'how can parents talk to teens about pregnancy prevention':
        'Parents should have open, honest conversations about sex and relationships. Use age-appropriate information, encourage questions, and create a safe environment for discussion.',
    'what is comprehensive sex education':
        'Comprehensive sex education includes information about abstinence, contraception, STIs, healthy relationships, and consent. It helps young people make informed decisions.',
    'where can teens get contraception':
        'Teens can access contraception from healthcare clinics, Planned Parenthood, school health centers, and private doctors. Many offer confidential services.',
    'what is consent':
        'Consent means giving clear, voluntary permission for any sexual activity. It can be withdrawn at any time, and cannot be given by someone who is underage, intoxicated, or coerced.',
    'what are STIs':
        'Sexually Transmitted Infections (STIs) are infections passed through sexual contact. Using condoms and getting regular testing helps prevent and detect STIs.',
    'how can STIs be prevented':
        'STIs can be prevented by abstaining from sex, using condoms correctly, limiting sexual partners, getting vaccinated (for HPV), and regular testing.',
    'what is HPV':
        'HPV (Human Papillomavirus) is a common STI that can cause genital warts and certain cancers. The HPV vaccine is recommended for teens and young adults.',
    'what is chlamydia':
        'Chlamydia is a common bacterial STI that can cause fertility problems if untreated. It often has no symptoms, so regular testing is important.',
    'what is gonorrhea':
        'Gonorrhea is a bacterial STI that can cause infertility and other complications if untreated. It can be treated with antibiotics.',
    'what is HIV':
        'HIV (Human Immunodeficiency Virus) attacks the immune system and can lead to AIDS. It is preventable through safe sex practices and can be managed with treatment.',
    'how do healthy relationships help prevent teenage pregnancy':
        'Healthy relationships involve mutual respect, open communication, and shared decision-making. Partners in healthy relationships are more likely to discuss contraception and pregnancy prevention.',
    'what are signs of an unhealthy relationship':
        'Signs include controlling behavior, jealousy, isolation from friends/family, physical violence, and pressure to engage in sexual activity.',
    'what should I do if I think I might be pregnant':
        'If you think you might be pregnant, take a home pregnancy test or visit a healthcare provider. It is important to confirm the pregnancy and discuss options.',

    // Additional questions (26-50)
    'what is the morning after pill':
        'The morning-after pill (emergency contraception) is a medication that can be taken after unprotected sex to reduce the chance of pregnancy. It works best when taken soon after intercourse.',
    'how long does it take to get pregnant':
        'Fertility varies, but a healthy couple trying to conceive typically achieves pregnancy within one year. Teens should know that pregnancy can happen quickly once sexually active.',
    'what is puberty':
        'Puberty is the process of physical changes when a child\'s body matures into an adult body capable of reproduction. It typically begins between ages 8-13 in girls.',
    'what is ovulation':
        'Ovulation is when an egg is released from the ovary. It usually happens about midway through the menstrual cycle and is the time when pregnancy is most likely to occur.',
    'what is the menstrual cycle':
        'The menstrual cycle is the monthly process of hormone changes that prepares the body for pregnancy. It includes menstruation (period), ovulation, and the luteal phase.',
    'what is a healthy relationship':
        'A healthy relationship involves mutual respect, trust, honest communication, equality, and consent. Both partners support each other\'s goals and well-being.',
    'how to say no to sex':
        'It is perfectly okay to say no to sex. You can say "I\'m not ready," "I don\'t want to," or simply "No." Healthy relationships respect boundaries and decisions.',
    'what is sexual coercion':
        'Sexual coercion is pressuring or manipulating someone into sexual activity against their will. It is a form of sexual assault and is never acceptable.',
    'what are long-acting reversible contraceptives':
        'Long-Acting Reversible Contraceptives (LARCs) include IUDs and implants. They are highly effective, last for years, and can be removed anytime to restore fertility.',
    'what is the pull out method':
        'The withdrawal method (pulling out before ejaculation) is about 78% effective. It is less reliable than other methods and does not protect against STIs.',
    'what is fertility awareness':
        'Fertility awareness involves tracking ovulation to avoid pregnancy. It requires careful monitoring and is less effective than other methods.',
    'what is teen parenting':
        'Teen parenting involves raising a child as a teenager. It presents challenges including financial strain, educational interruptions, and limited job opportunities.',
    'how does poverty relate to teenage pregnancy':
        'Teenage pregnancy is both a cause and consequence of poverty. Teens in disadvantaged circumstances often face barriers to education and contraception access.',
    'what is the role of media in teenage pregnancy':
        'Media can influence attitudes about sex and relationships. Positive media literacy helps teens critically evaluate messages about sexuality.',
    'how do cultural factors affect teenage pregnancy':
        'Cultural norms, family values, and community expectations can influence decisions about sexual behavior and pregnancy prevention.',
    'what is the law about teenage pregnancy':
        'Laws vary by country but typically protect teens\' right to confidential healthcare services including contraception and STI testing.',
    'can teens consent to sex':
        'Age of consent laws vary by country/state. It is important to understand local laws as well as the emotional maturity required for sexual activity.',
    'what is date rape':
        'Date rape is sexual assault by someone the victim knows, such as a date or boyfriend. It is never the victim\'s fault, and help is available.',
    'how to protect yourself from pregnancy':
        'Use effective contraception consistently, use condoms to prevent STIs, communicate with your partner about protection, and seek healthcare provider advice.',
    'what is reproductive health':
        'Reproductive health includes access to information, education, and services for preventing and addressing issues related to sexual and reproductive health.',
    'what is a teenager':
        'A teenager is someone between ages 13-19. This is a time of significant physical, emotional, and social development.',
    'what causes teenage pregnancy':
        'Causes include lack of sex education, limited access to contraception, poverty, peer pressure, and unhealthy relationships. Comprehensive prevention addresses all these factors.',
    'why is teenage pregnancy a problem':
        'Teenage pregnancy affects health, education, and economic outcomes for young parents and their children. Prevention supports better futures.',
    'what are teen pregnancy statistics':
        'Teen pregnancy rates vary by country. In many places, rates have declined due to improved sex education and contraception access.',
    'how to prevent stis':
        'Prevent STIs by abstaining from sex, using condoms, limiting partners, getting vaccinated, and regular testing. Early detection and treatment are important.',

    // Additional questions (91-120) — aligned to shelves: Pregnancy Care, Birth Control Methods, Vitamins

    // ---------------- PREGNANCY CARE SHELF ----------------
    'why is attending antenatal clinic early important':
        'Attending antenatal clinic early allows health workers to examine the mother, confirm the pregnancy, and identify any health problems at an early stage. Early care helps prevent complications, ensures proper nutrition advice, and allows the mother to receive important services such as vaccinations, health education, and regular monitoring of the baby’s growth.',

    'what happens during an antenatal visit':
        'During an antenatal visit, the health worker checks the mother’s weight, blood pressure, and overall health. They may also test blood and urine, listen to the baby’s heartbeat, provide vitamins, and give advice about nutrition, hygiene, and safe pregnancy practices. These visits help ensure both the mother and baby remain healthy throughout pregnancy.',

    'why is personal hygiene important during pregnancy':
        'Personal hygiene helps prevent infections that could harm both the mother and the baby. Regular bathing, wearing clean clothes, washing hands before eating, and keeping the living environment clean reduce the risk of illness and support a healthy pregnancy.',

    'why should pregnant teenagers avoid heavy work':
        'Heavy physical work can cause tiredness, stress, and strain on the body during pregnancy. It may increase the risk of injury or complications. Pregnant teenagers are encouraged to rest when tired and avoid lifting heavy objects to protect their health and the baby’s development.',

    'why is sleeping under a mosquito net important during pregnancy':
        'Sleeping under a mosquito net helps prevent malaria, which is dangerous during pregnancy. Malaria can cause fever, anemia, and low birth weight in babies. Using a treated mosquito net every night is an important way to protect both mother and baby.',

    'what are healthy habits during pregnancy':
        'Healthy habits during pregnancy include eating balanced meals, drinking clean water, attending clinic visits, getting enough rest, exercising lightly, and avoiding harmful substances like alcohol or tobacco. These habits support healthy growth and reduce the risk of complications.',

    'why is emotional support important for pregnant teenagers':
        'Emotional support from family, friends, and health workers helps pregnant teenagers feel safe, confident, and less stressed. Support improves mental health, encourages healthy behaviors, and helps teenagers prepare for motherhood and childcare responsibilities.',

    'why should pregnant women prepare for delivery early':
        'Preparing for delivery early helps ensure that the mother knows where to give birth, how to reach the health facility, and what items to bring. Planning ahead reduces stress and helps prevent delays in receiving medical care during labor.',

    // ---------------- BIRTH CONTROL METHODS SHELF ----------------
    'why is family planning important for teenagers':
        'Family planning allows teenagers to delay pregnancy until they are physically, emotionally, and financially ready. It helps them continue their education, achieve career goals, and make responsible decisions about their future health and family life.',

    'what is birth preparedness':
        'Birth preparedness means planning ahead for delivery by choosing a health facility, arranging transport, saving money for medical costs, and preparing necessary items such as clean clothes and baby supplies. Proper preparation helps reduce delays and improves the chances of a safe delivery.',

    'why is it important to know the expected delivery date':
        'Knowing the expected delivery date helps the mother and family prepare for childbirth, plan clinic visits, and recognize when labor is approaching. It also helps health workers monitor the baby’s growth and identify any delays or complications.',

    'what are the benefits of delivering at a health facility':
        'Delivering at a health facility ensures that trained health workers and medical equipment are available to manage complications. This reduces the risk of infections, bleeding, and other emergencies that can threaten the lives of the mother and baby.',

    'why is monitoring blood pressure important during pregnancy':
        'Monitoring blood pressure helps detect conditions such as high blood pressure, which can lead to serious complications for both mother and baby. Regular checks allow early treatment and safer pregnancy outcomes.',

    'what is the importance of taking prescribed medication during pregnancy':
        'Taking prescribed medication ensures that health conditions such as infections or anemia are properly treated. Following medical instructions helps prevent complications and supports healthy development of the baby.',

    'why should pregnant women avoid self-medication':
        'Self-medication can be dangerous because some drugs may harm the baby or cause complications. Pregnant women should only take medicines recommended by qualified health professionals.',

    'what role does proper nutrition play in preventing complications':
        'Proper nutrition provides the nutrients needed for strong immunity, healthy blood production, and baby growth. Good nutrition reduces the risk of anemia, weakness, and low birth weight.',

    'how can pregnant teenagers maintain good mental health':
        'Pregnant teenagers can maintain good mental health by seeking emotional support, attending counseling if needed, resting adequately, and participating in positive activities such as education or hobbies.',
    'how do condoms prevent pregnancy':
        'Condoms prevent pregnancy by acting as a barrier that stops sperm from entering the uterus. When used correctly every time, condoms are effective at preventing pregnancy and also provide protection against sexually transmitted infections.',

    'why should teenagers learn about birth control methods':
        'Learning about birth control methods helps teenagers make informed decisions about their health and relationships. Knowledge about contraception reduces the risk of unintended pregnancy and promotes responsible behavior.',

    'what are advantages of using condoms':
        'Condoms are easy to use, affordable, and widely available. They provide protection against both pregnancy and sexually transmitted infections. They do not require a medical procedure and can be used only when needed.',

    'what should teenagers consider before choosing a birth control method':
        'Teenagers should consider their health, lifestyle, ability to use the method correctly, and advice from a healthcare provider. Choosing the right method ensures effectiveness, safety, and comfort.',

    'can birth control methods fail':
        'Yes, birth control methods can fail if they are not used correctly or consistently. For example, forgetting to take pills or using condoms incorrectly can reduce effectiveness. Proper use and guidance from health workers improve protection.',

    'why is communication with a partner important when using contraception':
        'Communication helps partners agree on safe and responsible decisions. Discussing contraception openly builds trust, ensures consistent use, and reduces the risk of unintended pregnancy.',

    'what is the safest way to prevent pregnancy':
        'Abstinence, which means choosing not to have sexual activity, is the safest and most effective way to prevent pregnancy and sexually transmitted infections. It allows teenagers to focus on education and personal development.',

    // ---------------- VITAMINS SHELF ----------------
    'why are vitamins important during pregnancy':
        'Vitamins provide essential nutrients that support the healthy growth and development of the baby and help maintain the mother’s health. They strengthen the immune system, support bone development, and reduce the risk of complications during pregnancy.',

    'why is consistent vitamin intake important during pregnancy':
        'Consistent vitamin intake ensures that the body receives a steady supply of essential nutrients needed for baby development and maternal health. Missing doses frequently can lead to nutrient deficiencies and increase the risk of complications.',

    'how do vitamins support baby development':
        'Vitamins support the formation of organs, bones, blood, and the nervous system. They help ensure that the baby grows properly and reduce the risk of developmental problems.',

    'why is it important to follow the correct vitamin dosage':
        'Taking the correct vitamin dosage ensures effectiveness and safety. Too little may not provide enough nutrients, while too much may cause harmful side effects. Health workers provide guidance on proper dosage.',

    'can vitamins prevent all pregnancy complications':
        'Vitamins help reduce certain risks but cannot prevent all complications. Regular clinic visits, healthy nutrition, and medical care are also necessary for a safe pregnancy.',

    'why are prenatal supplements recommended for teenagers':
        'Teenagers require extra nutrients because their bodies are still growing while supporting the baby’s development. Prenatal supplements help meet these increased nutritional needs.',

    'what happens if a pregnant teenager has vitamin deficiency':
        'Vitamin deficiency can cause health problems such as anemia, weak bones, poor baby growth, and increased risk of illness. Early detection and proper supplementation help correct deficiencies.',

    'how do health workers monitor nutritional status during pregnancy':
        'Health workers monitor nutritional status through regular check-ups, blood tests, and weight measurements. They provide advice on diet and may recommend supplements to ensure both mother and baby receive necessary nutrients.',
    'what happens if a pregnant woman does not take vitamins':
        'Not taking vitamins may lead to nutrient deficiencies, which can cause weakness, anemia, poor baby growth, or health complications. Regular vitamin intake helps ensure the body receives the nutrients needed for a healthy pregnancy.',

    'why is folic acid important in early pregnancy':
        'Folic acid supports the formation of the baby’s brain and spinal cord during early pregnancy. Taking folic acid reduces the risk of birth defects and supports healthy development of the nervous system.',

    'why should pregnant women take iron tablets':
        'Iron tablets help increase the number of red blood cells in the body and prevent anemia. This ensures enough oxygen is delivered to the baby and helps the mother maintain energy and strength during pregnancy.',

    'why is calcium important for pregnant teenagers':
        'Calcium helps build strong bones and teeth for the baby and protects the mother’s bones from becoming weak. Teenagers need extra calcium because their own bodies are still growing.',

    'why is vitamin d important during pregnancy':
        'Vitamin D helps the body absorb calcium and supports the development of strong bones and teeth in the baby. It also helps maintain a healthy immune system for both mother and child.',

    'when should pregnant women take vitamins':
        'Pregnant women should take vitamins daily as advised by a healthcare provider. Taking vitamins regularly ensures the body receives consistent nutrients needed for healthy pregnancy and baby development.',

    'can pregnant women get vitamins from food':
        'Yes, many vitamins come from healthy foods such as fruits, vegetables, milk, eggs, beans, and fish. However, supplements are often recommended to ensure the body receives enough nutrients during pregnancy.',

    // ---------------- GAME / EDUCATION INTERACTION SUPPORT ----------------
    'why is visiting a health facility important during pregnancy':
        'Health facilities provide professional care, medical tests, and emergency support when needed. Regular visits help detect problems early and ensure safe pregnancy and delivery.',

    'why is clean drinking water important during pregnancy':
        'Clean drinking water helps prevent infections, supports digestion, and keeps the body hydrated. Proper hydration is essential for maintaining good health during pregnancy.',

    'why should pregnant women eat balanced meals':
        'Balanced meals provide the nutrients needed for energy, baby growth, and strong immunity. Eating a variety of foods ensures both mother and baby remain healthy throughout pregnancy.',

    'why should pregnant teenagers avoid alcohol and smoking':
        'Alcohol and smoking can harm the baby’s development and increase the risk of birth defects, low birth weight, and health complications. Avoiding these substances helps protect the baby and supports healthy pregnancy.',

    // ---------------- NEWBORN AND POST-DELIVERY CARE ----------------
    'why is skin to skin contact important after birth':
        'Skin to skin contact helps regulate the baby’s body temperature, strengthens bonding between mother and baby, and supports early breastfeeding.',

    'why is keeping the baby warm important':
        'Newborn babies lose heat quickly. Keeping the baby warm prevents illness, supports healthy breathing, and improves survival.',

    'why should newborns be taken for regular checkups':
        'Regular checkups allow health workers to monitor growth, detect illnesses early, and provide vaccinations and health advice.',

    'how can mothers recognize illness in a newborn':
        'Signs of illness in a newborn may include fever, difficulty breathing, poor feeding, unusual crying, or weakness. Immediate medical care is necessary if these signs appear.',

    // ---------------- SYSTEM / CHATBOT TESTING STYLE QUESTIONS ----------------
    'how does health education improve maternal outcomes':
        'Health education provides knowledge about pregnancy care, nutrition, and danger signs. Informed mothers are more likely to seek medical help early and follow healthy practices, leading to better outcomes.',

    'why is community awareness important in preventing teenage pregnancy':
        'Community awareness encourages responsible behavior, supports education, and reduces stigma. It creates an environment where teenagers receive guidance and support.',

    'how can technology support maternal health education':
        'Technology such as mobile applications and chatbots provides easy access to health information, reminders, and guidance. It helps users learn anytime and supports decision-making.',

    'what is the role of health education in reducing maternal mortality':
        'Health education helps women understand safe pregnancy practices, recognize danger signs, and seek timely medical care. These actions reduce the risk of death during pregnancy and childbirth.',

    'why is continuous learning important for pregnant teenagers':
        'Continuous learning helps pregnant teenagers gain knowledge about health, parenting, and life skills. Education empowers them to make responsible decisions and improve their future.',

    'how does planning improve pregnancy outcomes':
        'Planning allows families to prepare financially, emotionally, and medically for pregnancy and childbirth. Preparation reduces stress and improves safety for both mother and baby.',
    'what are folic acids for':
        'Folic acid is a type of vitamin that helps the baby’s brain and spinal cord develop properly during early pregnancy. It reduces the risk of birth defects and supports healthy growth of the nervous system. Pregnant women are usually advised to take folic acid daily, especially in the first months of pregnancy.',

    'examples of prenatal vitamins':
        'Examples of prenatal vitamins include folic acid, iron, calcium, vitamin D, iodine, and vitamin C. These vitamins support baby development, strengthen the mother’s body, prevent anemia, build strong bones, and improve the immune system during pregnancy.',

    'what is iron supplement in pregnancy':
        'An iron supplement is a vitamin tablet given to pregnant women to increase the amount of healthy red blood cells in the body. It helps prevent anemia, reduces tiredness, and ensures enough oxygen is carried to the baby for proper growth.',

    'what is calcium supplement in pregnancy':
        'A calcium supplement is a nutrient taken during pregnancy to help build strong bones and teeth for the baby. It also protects the mother’s bones from becoming weak and supports proper muscle and nerve function.',

    'what is vitamin d used for in pregnancy':
        'Vitamin D helps the body absorb calcium and supports the development of strong bones and teeth in the baby. It also helps maintain a healthy immune system and reduces the risk of bone problems.',

    'what is iodine supplement in pregnancy':
        'Iodine is a nutrient that supports the development of the baby’s brain and nervous system. It also helps regulate hormones in the body and supports healthy growth during pregnancy.',

    // ---------------- EXAMPLES OF SPECIFIC PRENATAL VITAMINS ----------------
    'give examples of folic acid foods':
        'Examples of foods rich in folic acid include green leafy vegetables such as spinach, beans, oranges, and fortified cereals. These foods help support healthy baby development and prevent birth defects.',

    'give examples of iron rich foods for pregnancy':
        'Examples of iron-rich foods include beans, liver, meat, eggs, and dark green vegetables. These foods help prevent anemia and improve energy levels during pregnancy.',

    'give examples of calcium rich foods for pregnancy':
        'Examples of calcium-rich foods include milk, yogurt, cheese, small fish eaten with bones, and green vegetables. These foods help build strong bones and teeth for both mother and baby.',

    // ---------------- PREGNANCY CARE METHODS SHELF ----------------
    'examples of pregnancy care methods':
        'Examples of pregnancy care methods include attending antenatal clinic visits, eating a balanced diet, getting enough rest, sleeping under a mosquito net, maintaining personal hygiene, and preparing for delivery. These practices help protect the health of both mother and baby during pregnancy.',

    'what is antenatal care':
        'Antenatal care is the medical care a pregnant woman receives during pregnancy. It includes health checkups, monitoring the baby’s growth, receiving vaccinations, and getting advice on nutrition and safety. Regular antenatal visits help detect problems early and ensure a safe pregnancy.',

    'what is balanced diet in pregnancy':
        'A balanced diet in pregnancy means eating a variety of healthy foods such as fruits, vegetables, proteins, and grains. This provides the nutrients needed for baby growth, energy, and strong immunity for the mother.',

    'what is rest during pregnancy':
        'Rest during pregnancy means giving the body enough time to relax and recover. Proper rest reduces stress, prevents tiredness, and supports healthy development of the baby.',

    'what is sleeping under a mosquito net':
        'Sleeping under a mosquito net is a method of preventing mosquito bites that can cause malaria. Malaria is dangerous during pregnancy and can lead to illness, anemia, or low birth weight in babies.',

    'what is birth preparedness':
        'Birth preparedness means planning ahead for delivery by choosing a health facility, arranging transport, saving money, and preparing necessary items. This helps ensure safe and timely medical care during labor.',

    'give examples of pregnancy care items':
        'Examples of pregnancy care items include mosquito nets, clean drinking water, antenatal clinic cards, healthy food, comfortable clothing, and delivery kits. These items help maintain hygiene, prevent disease, and support safe pregnancy and childbirth.',

    'examples of birth control methods':
        'Examples of birth control methods include condoms, birth control pills, implants, intrauterine devices (IUDs), and abstinence. These methods help prevent unintended pregnancy and allow individuals to plan when to have children.',

    'what is a condom':
        'A condom is a protective covering worn during sexual activity. It prevents sperm from entering the uterus, reducing the chance of pregnancy. Condoms also protect against sexually transmitted infections.',

    'what is a birth control pill':
        'A birth control pill is a medication taken daily that contains hormones to prevent ovulation, which means no egg is released for fertilization. This helps prevent pregnancy when used correctly.',

    'what is an implant birth control method':
        'An implant is a small, flexible rod placed under the skin of the upper arm by a health professional. It releases hormones slowly to prevent pregnancy for several years.',

    'what is an intrauterine device':
        'An intrauterine device, also called an IUD, is a small device inserted into the uterus by a trained health worker. It prevents pregnancy for several years and can be removed when a person wants to have children.',

    'what is abstinence as a birth control method':
        'Abstinence means choosing not to have sexual activity. It is the only method that completely prevents pregnancy and sexually transmitted infections when practiced consistently.',

    // ---------------- GAME / SHELF SUPPORT QUESTIONS ----------------
    'why are vitamins placed on the pregnancy shelf':
        'Vitamins are placed on the pregnancy shelf because they provide essential nutrients that support baby development, prevent health problems, and keep the mother strong during pregnancy.',

    'why are condoms placed on the birth control shelf':
        'Condoms are placed on the birth control shelf because they are used to prevent pregnancy and protect against infections during sexual activity.',

    'why is antenatal care placed on the pregnancy care shelf':
        'Antenatal care is placed on the pregnancy care shelf because it is an important health service that helps monitor pregnancy, detect problems early, and ensure safe delivery.',
  };

  // Expanded keyword topics for better matching - 15 topics with more keywords
  final List<Map<String, dynamic>> _keywordTopics = [
    {
      'keywords': [
        'prevent',
        'prevention',
        'avoid pregnancy',
        'stop pregnancy',
        'not pregnant',
        'contraception',
        'birth control',
        'condom',
        'pill',
        'iud',
        'implant',
        'protection',
        'safe sex',
        'contraceptives',
        'methods',
        'family planning',
        'preventing pregnancy',
        'how to not get pregnant',
        'avoid getting pregnant',
      ],
      'topic': 'prevention',
    },
    {
      'keywords': [
        'risk',
        'risks',
        'danger',
        'problems',
        'complications',
        'health risks',
        'negative effects',
        'consequences',
        'unsafe',
        'harmful',
        'dangerous',
        'side effects',
        'issues',
        'challenges',
        'difficulties',
      ],
      'topic': 'risks',
    },
    {
      'keywords': [
        'condom',
        'condoms',
        'male condom',
        'female condom',
        'rubber',
        'protection',
        'latex',
        'barrier method',
        'safe sex',
        'std prevention',
        'sti prevention',
        'prevent disease',
        'prevent infection',
      ],
      'topic': 'condoms',
    },
    {
      'keywords': [
        'pill',
        'birth control pill',
        'oral contraceptive',
        'contraceptive pill',
        'daily pill',
        'hormonal pill',
        'take pill',
        'pills',
        'medication',
        'prescription',
        'doctor prescribed',
      ],
      'topic': 'pill',
    },
    {
      'keywords': [
        'iud',
        'intrauterine',
        'copper iud',
        'hormonal iud',
        'mirena',
        'skyla',
        'loop',
        'device',
        'long acting',
        'larc',
        'longterm',
        'years',
      ],
      'topic': 'iud',
    },
    {
      'keywords': [
        'implant',
        'nexplanon',
        'rod',
        'arm implant',
        'birth control implant',
        'subdermal',
        '3 years',
        'long lasting',
        'progestin',
      ],
      'topic': 'implant',
    },
    {
      'keywords': [
        'emergency',
        'morning after',
        'day after',
        'plan b',
        'ella',
        'ulipristal',
        'accident',
        'unprotected',
        'broken condom',
        'forgot pill',
        'emergency pill',
      ],
      'topic': 'emergency',
    },
    {
      'keywords': [
        'education',
        'learn',
        'teach',
        'information',
        'knowledge',
        'school',
        'class',
        'course',
        'workshop',
        'talk',
        'discuss',
        'understand',
        'awareness',
        'facts',
        'truth',
        'myths',
      ],
      'topic': 'education',
    },
    {
      'keywords': [
        'stds',
        'sti',
        'stis',
        'sexually transmitted',
        'disease',
        'infection',
        'chlamydia',
        'gonorrhea',
        'syphilis',
        'herpes',
        'hpv',
        'hiv',
        'aids',
        'virus',
        'bacterial',
        'treatment',
        'cure',
        'test',
        'testing',
      ],
      'topic': 'stis',
    },
    {
      'keywords': [
        'relationship',
        'relationships',
        'dating',
        'boyfriend',
        'girlfriend',
        'partner',
        'love',
        'marriage',
        'commitment',
        'trust',
        'respect',
        'communication',
        'healthy',
        'unhealthy',
        'abusive',
        'violence',
      ],
      'topic': 'relationships',
    },
    {
      'keywords': [
        'parent',
        'parents',
        'mom',
        'dad',
        'mother',
        'father',
        'family',
        'talk',
        'conversation',
        'discuss',
        'communication',
        'advice',
        'guidance',
        'support',
        'help',
        'family planning',
      ],
      'topic': 'parenting',
    },
    {
      'keywords': [
        'abstinence',
        'wait',
        'waiting',
        'not having sex',
        'celibacy',
        'virgin',
        'virginity',
        'save',
        'reserve',
        'delay',
        'delaying',
        'later',
        'ready',
        'not ready',
        'when',
      ],
      'topic': 'abstinence',
    },
    {
      'keywords': [
        'pregnant',
        'pregnancy',
        'baby',
        'child',
        'expecting',
        'conception',
        'conceive',
        'trying',
        'fertility',
        'fertile',
        'egg',
        'sperm',
        'zygote',
        'fetus',
        'trimester',
        'prenatal',
      ],
      'topic': 'pregnancy',
    },
    {
      'keywords': [
        'teen',
        'teenager',
        'teenage',
        'young',
        'youth',
        'adolescent',
        'adolescence',
        'child',
        'kid',
        'school',
        'high school',
        'college',
        'student',
        'young adult',
      ],
      'topic': 'teens',
    },
    {
      'keywords': [
        'consent',
        'agree',
        'permission',
        'willing',
        'want',
        'desire',
        'no',
        'yes',
        'forced',
        'coerced',
        'pressured',
        'rape',
        'assault',
        'attack',
        'violate',
        'respect',
        'boundaries',
        'limits',
      ],
      'topic': 'consent',
    },
  ];

  // Keyword matching threshold (lowered from 0.3 to 0.2 for better matching)
  static const double _keywordThreshold = 0.15; // Lowered for better matching

  /// Get download progress (0.0 to 1.0)
  double get downloadProgress => _downloadProgress;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        _isModelDownloaded = prefs.getBool('model_downloaded') ?? false;
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final modelPath = '${directory.path}/$_modelFileName';
        _modelFile = File(modelPath);
        _isModelDownloaded = await _modelFile!.exists();
      }
      _isInitialized = true;
    } catch (e) {
      // Model not found - will use offline Q&A
    }
  }

  /// Download the AI model - returns a Stream of download progress
  Stream<double> downloadModel() async* {
    try {
      _downloadProgress = 0.0;

      // Simulate download progress for demo purposes
      // In a real app, this would download from a server
      final Uint8List modelData = Uint8List.fromList(
        List.generate(1024 * 1024, (i) => i % 256),
      ); // 1MB placeholder

      for (int i = 0; i <= 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        _downloadProgress = i / 10.0;
        yield _downloadProgress;
      }

      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('model_downloaded', true);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final modelPath = '${directory.path}/$_modelFileName';
        _modelFile = File(modelPath);
        await _modelFile!.writeAsBytes(modelData);
      }

      _isModelDownloaded = true;
      _isInitialized = true;
      _downloadProgress = 1.0;
      yield _downloadProgress;
    } catch (e) {
      _downloadProgress = 0.0;
      rethrow;
    }
  }

  /// Delete the downloaded model
  Future<void> deleteModel() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('model_downloaded', false);
      } else if (_modelFile != null && await _modelFile!.exists()) {
        await _modelFile!.delete();
      }
      _modelFile = null;
      _isModelDownloaded = false;
      _isInitialized = false;
    } catch (e) {
      rethrow;
    }
  }

  Stream<String> getResponse(String query) async* {
    // Normalize query: lowercase + strip punctuation + normalize spaces
    String normalizedQuery = _normalizeQuery(query);

    // First try exact match on normalized
    if (_questionAnswers.containsKey(normalizedQuery)) {
      yield _questionAnswers[normalizedQuery]!;
      return;
    }

    // Try partial match (normalized query vs original keys)
    for (var entry in _questionAnswers.entries) {
      final normKey = _normalizeQuery(entry.key);
      if (normalizedQuery.contains(normKey) ||
          normKey.contains(normalizedQuery)) {
        yield entry.value;
        return;
      }
    }

    // Use keyword matching
    final bestMatch = _findBestKeywordMatch(normalizedQuery);
    if (bestMatch != null) {
      yield bestMatch;
      return;
    }

    // Try keyword matching on topic keywords
    final topicMatch = _findTopicMatch(normalizedQuery);
    if (topicMatch != null) {
      yield topicMatch;
      return;
    }

    // Default fallback response
    yield _getFallbackResponse(normalizedQuery);
  }

  String? _findBestKeywordMatch(String query) {
    double bestScore = 0;
    String? bestAnswer;

    for (var entry in _questionAnswers.entries) {
      final normKey = _normalizeQuery(entry.key);
      final score = _calculateSimilarity(query, normKey);
      if (score > bestScore && score >= _keywordThreshold) {
        bestScore = score;
        bestAnswer = entry.value;
      }
    }

    return bestAnswer;
  }

  String? _findTopicMatch(String query) {
    for (var topic in _keywordTopics) {
      final keywords = topic['keywords'] as List<String>;
      int matchCount = 0;

      for (var keyword in keywords) {
        if (query.contains(keyword)) {
          matchCount++;
        }
      }

      if (matchCount >= 2) {
        return _getTopicResponse(topic['topic'] as String);
      }
    }
    return null;
  }

  String _getTopicResponse(String topic) {
    switch (topic) {
      case 'prevention':
        return 'Pregnancy prevention methods include abstinence (not having sex), condoms, birth control pills, IUDs, implants, and emergency contraception. Each method has different effectiveness rates. Condoms also help prevent STIs. Consider talking to a healthcare provider about which option is best for you.';
      case 'risks':
        return 'Teenage pregnancy can have health risks like premature birth and low birth weight. There are also social and economic challenges including interrupted education and financial strain. However, with proper support, many teen parents succeed. Prevention and access to resources are key.';
      case 'condoms':
        return 'Condoms are a barrier method that prevent pregnancy and protect against STIs. Male condoms are about 85-98% effective when used correctly. Female condoms are also available. Always use condoms properly and check the expiration date.';
      case 'pill':
        return 'Birth control pills are highly effective (over 99%) when taken correctly every day. They contain hormones that prevent ovulation. Some benefits include lighter periods and reduced acne. Side effects can vary - talk to a doctor about what\'s right for you.';
      case 'iud':
        return 'IUDs are small T-shaped devices inserted into the uterus by a healthcare provider. They can prevent pregnancy for 3-10 years depending on the type. IUDs are over 99% effective and can be removed anytime to restore fertility.';
      case 'implant':
        return 'The birth control implant is a small rod placed under the skin of the upper arm. It releases hormones to prevent pregnancy for up to 3 years. It is over 99% effective and one of the most effective reversible methods available.';
      case 'emergency':
        return 'Emergency contraception (morning-after pill) can be used after unprotected sex to prevent pregnancy. It is most effective when taken as soon as possible. It is not intended for regular use and does not protect against STIs.';
      case 'education':
        return 'Comprehensive sex education provides accurate information about contraception, STIs, healthy relationships, and consent. Research shows that sex education helps teens make healthier decisions and delays sexual activity.';
      case 'stis':
        return 'STIs (Sexually Transmitted Infections) can affect anyone who is sexually active. Using condoms reduces risk. Regular testing is important because many STIs have no symptoms. Many are treatable with antibiotics. Some STIs like HIV require ongoing management.';
      case 'relationships':
        return 'Healthy relationships involve mutual respect, trust, and open communication. Both partners should feel comfortable discussing contraception and sexual health. Unhealthy relationships may involve pressure or control. If you feel unsafe, seek help.';
      case 'parenting':
        return 'Parents play an important role in teen sexual health. Open, honest conversations help teens make better decisions. Create a safe environment for questions. Talk about abstinence, contraception, and healthy relationships.';
      case 'abstinence':
        return 'Abstinence means choosing not to have sex. It is the only 100% effective way to prevent pregnancy and STIs. Many young people choose to wait until they are older and in a committed relationship. This is a healthy and valid choice.';
      case 'pregnancy':
        return 'Pregnancy occurs when an egg is fertilized by sperm. For teens, pregnancy can have health and social challenges. If you think you might be pregnant, take a test and consult a healthcare provider. Options include prenatal care, adoption, or other choices.';
      case 'teens':
        return 'Teenage years are a time of growth and development. Making healthy choices about relationships and sexual activity is important. Understanding your body, consent, and prevention methods helps you make informed decisions.';
      case 'consent':
        return 'Consent means giving clear permission for sexual activity. It can be withdrawn anytime. You have the right to say no. Sexual activity without consent is assault. Everyone deserves to have their boundaries respected.';
      default:
        return 'For more information about teenage pregnancy prevention, talk to a healthcare provider, school counselor, or trusted adult. There are many resources available to help you make healthy decisions.';
    }
  }

  String _getFallbackResponse(String query) {
    // Vary fallback based on keywords to avoid "same reply"
    if (query.contains('pregnan')) {
      return 'Teenage pregnancy prevention is important for your health and future. Key methods include abstinence, condoms, birth control pills, IUDs, and implants. Talk to a healthcare provider for personalized advice.';
    } else if (query.contains('prevent') || query.contains('stop')) {
      return 'Effective prevention includes not having sex (abstinence), using condoms every time, birth control methods, and emergency contraception when needed. Comprehensive sex education helps too.';
    } else if (query.contains('what') ||
        query.contains('how') ||
        query.contains('why')) {
      return 'Great question about reproductive health! Common topics include prevention methods, risks of teen pregnancy, contraception options, and healthy relationships. Ask more specifically or visit a clinic.';
    }
    return 'For teenage pregnancy prevention info, talk to a healthcare provider, school counselor, or trusted adult. They offer confidential help on contraception, STIs, and healthy choices.';
  }

  /// Normalize query: lowercase, remove punctuation, normalize spaces
  String _normalizeQuery(String query) {
    return query
        .toLowerCase()
        // Remove common punctuation but keep words intact
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        // Multiple spaces to single
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _calculateSimilarity(String text1, String text2) {
    // Split into words and filter empty
    final words1 = text1.split(' ').where((w) => w.isNotEmpty).toSet();
    final words2 = text2.split(' ').where((w) => w.isNotEmpty).toSet();

    if (words1.isEmpty || words2.isEmpty) return 0;

    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;

    final score = intersection / union;
    return score;
  }

  bool get isModelDownloaded => _isModelDownloaded;

  bool get isModelLoaded => _isInitialized && _isModelDownloaded;
}
