//
//  FlashcardData.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import Foundation

struct FlashcardData {
    static let defaultDecks: [FlashcardDeck] = [
        // 1. Drivetrain Basics
        FlashcardDeck(
            title: "Drivetrain Basics",
            description: "Essential drivetrain concepts, types, and selection",
            category: .technical,
            icon: "gearshape.2.fill",
            flashcards: [
                Flashcard(front: "What is a drivetrain?", back: "The drivetrain is the system that provides power and motion to the robot's wheels, determining how the robot moves and turns.", category: "Drivetrains", difficulty: .beginner),
                Flashcard(front: "What is the main advantage of Mecanum drive?", back: "Holonomic movement - the ability to move in any direction (forward, backward, sideways, rotation) without turning.", category: "Drivetrains", difficulty: .intermediate),
                Flashcard(front: "What gear ratio provides more torque?", back: "Higher gear ratios (like 120:1) provide more torque but less speed. Lower ratios (like 20:1) provide more speed but less torque.", category: "Drivetrains", difficulty: .beginner),
                Flashcard(front: "What is tank drive also called?", back: "Skid-steer drive, because the robot skids when turning since wheels on each side move at different speeds.", category: "Drivetrains", difficulty: .beginner),
                Flashcard(front: "How many motors does a basic tank drive use?", back: "2-4 motors. Two motors for basic tank drive (one per side), four motors for more power (two per side).", category: "Drivetrains", difficulty: .beginner),
                Flashcard(front: "What is swerve drive?", back: "A drivetrain where each wheel can rotate independently, enabling precise positioning and movement in any direction. Very complex mechanically and programmatically.", category: "Drivetrains", difficulty: .advanced),
                Flashcard(front: "What gear ratio is typically used for drivetrains?", back: "20:1 or 40:1 for balanced speed and torque. 20:1 provides more speed, 40:1 provides more torque.", category: "Drivetrains", difficulty: .intermediate),
                Flashcard(front: "What is X-drive?", back: "A drivetrain with four wheels arranged in an X-pattern, enabling diagonal movement capabilities. Simpler than swerve but more complex than tank.", category: "Drivetrains", difficulty: .intermediate),
                Flashcard(front: "What is the main disadvantage of Mecanum drive?", back: "Requires precise programming, more complex to build, less pushing power than tank drive, and Mecanum wheels are expensive.", category: "Drivetrains", difficulty: .intermediate),
                Flashcard(front: "What power transmission methods are used in drivetrains?", back: "Gears, chains, or belts. Gears provide direct transmission, chains provide flexible transmission, belts provide quiet operation.", category: "Drivetrains", difficulty: .intermediate),
                Flashcard(front: "When should you choose tank drive?", back: "When you need simple control, good pushing power, reliability, or when your team is new to FTC. Best for most teams.", category: "Drivetrains", difficulty: .beginner),
                Flashcard(front: "When should you choose Mecanum drive?", back: "When you need precise positioning, tight spaces, sideways movement, or have advanced programming capabilities.", category: "Drivetrains", difficulty: .intermediate)
            ]
        ),
        
        // 2. Linear Motion Systems
        FlashcardDeck(
            title: "Linear Motion Systems",
            description: "Extension systems, slides, and linear mechanisms",
            category: .technical,
            icon: "arrow.up.and.down.and.arrow.left.and.right",
            flashcards: [
                Flashcard(front: "What is a linear motion system?", back: "A mechanism that provides extension beyond the robot's starting size constraints (18\" x 18\" x 18\"), allowing the robot to reach further.", category: "Linear Motion", difficulty: .beginner),
                Flashcard(front: "What is the minimum extension length teams typically need?", back: "Greater than 18 inches. Most teams prefer 24+ inches, and some games require 36+ inches.", category: "Linear Motion", difficulty: .beginner),
                Flashcard(front: "What are drawer slides?", back: "Simple, reliable extension mechanisms with good load capacity but limited extension length. Best for shorter extensions.", category: "Linear Motion", difficulty: .beginner),
                Flashcard(front: "What are extrusion slides?", back: "Linear slides made from aluminum extrusions that provide longer extension with good rigidity and customization options.", category: "Linear Motion", difficulty: .intermediate),
                Flashcard(front: "What is a lead screw?", back: "A threaded rod that provides precise positioning and self-locking capability, but is slower than other linear motion methods.", category: "Linear Motion", difficulty: .intermediate),
                Flashcard(front: "What is rack and pinion?", back: "A linear motion system using a gear (pinion) that engages with a toothed bar (rack), offering good speed and extension length.", category: "Linear Motion", difficulty: .intermediate),
                Flashcard(front: "What should you consider when selecting a linear slide?", back: "Extension length needed, load capacity required, speed requirements, and integration with robot structure.", category: "Linear Motion", difficulty: .beginner),
                Flashcard(front: "What is the load capacity of drawer slides?", back: "Typically 20-50 pounds, depending on the slide size and quality.", category: "Linear Motion", difficulty: .intermediate),
                Flashcard(front: "What safety factor should you use for linear slides?", back: "1.5-2x the expected load. If mechanism weighs 10 lbs, use slide rated for 15-20 lbs.", category: "Linear Motion", difficulty: .intermediate),
                Flashcard(front: "What is pivot extension?", back: "Combining arms with linear slides, allowing both horizontal and vertical extension while removing need for transfer stages.", category: "Linear Motion", difficulty: .advanced)
            ]
        ),
        
        // 3. Intake Systems
        FlashcardDeck(
            title: "Intake Systems",
            description: "Active and passive intakes, collection mechanisms",
            category: .technical,
            icon: "hand.raised.fill",
            flashcards: [
                Flashcard(front: "What is an active intake?", back: "An intake system using rotating wheels, rollers, or belts to pull game elements into the robot, providing fast collection.", category: "Intakes", difficulty: .beginner),
                Flashcard(front: "What is a passive intake?", back: "A mechanical mechanism (like a claw) that grasps individual elements, providing precise control but typically slower collection.", category: "Intakes", difficulty: .beginner),
                Flashcard(front: "What is the 'touch it, own it' principle?", back: "When intake contacts game elements, it should instantly control them. The intake should immediately grip or pull elements on contact.", category: "Intakes", difficulty: .beginner),
                Flashcard(front: "What motor speeds do top teams use for intakes?", back: "3.7:1 (1600 RPM) or 5.2:1 (1000 RPM) gear ratios for high-speed collection. Faster intakes are generally more effective.", category: "Intakes", difficulty: .intermediate),
                Flashcard(front: "How many motors should be dedicated to intake?", back: "At least one motor. Don't share intake motor with other mechanisms - dedicate it to intake for best performance.", category: "Intakes", difficulty: .beginner),
                Flashcard(front: "What materials work well for intake wheels?", back: "Compliant materials like rubber or foam provide better grip on game elements than hard plastic or metal.", category: "Intakes", difficulty: .intermediate),
                Flashcard(front: "What is intake geometry?", back: "The shape and design of the intake that guides elements to the collection point. Funnel shapes work well for guiding elements.", category: "Intakes", difficulty: .intermediate),
                Flashcard(front: "What should you consider when designing an intake?", back: "Element properties (size, shape, weight, surface), collection speed needed, reliability requirements, and integration with transfer systems.", category: "Intakes", difficulty: .beginner),
                Flashcard(front: "Why are faster intakes more effective?", back: "Faster intakes can collect elements more quickly, reducing time spent collecting and allowing more time for scoring.", category: "Intakes", difficulty: .intermediate),
                Flashcard(front: "What is a transfer system?", back: "The mechanism that moves collected elements from the intake to storage or scoring mechanisms.", category: "Intakes", difficulty: .intermediate)
            ]
        ),
        
        // 4. Arms and Linkages
        FlashcardDeck(
            title: "Arms and Linkages",
            description: "Arm design, pivot extensions, and linkage mechanisms",
            category: .technical,
            icon: "arrow.up.right.and.arrow.down.left",
            flashcards: [
                Flashcard(front: "What is a single-axis arm?", back: "A simple arm that rotates around one axis, providing limited extension (typically ~16\") due to starting size constraints.", category: "Arms", difficulty: .beginner),
                Flashcard(front: "What is pivot extension?", back: "Combining arms with linear slides, allowing linear extension to provide desired length for both horizontal and vertical extension.", category: "Arms", difficulty: .intermediate),
                Flashcard(front: "What reduction ratio is needed for long arms?", back: "254.5:1 or similar high ratios. Long arms require large reduction ratios to handle loads effectively.", category: "Arms", difficulty: .advanced),
                Flashcard(front: "Why should torque be transferred through gears/chains/belts?", back: "Rather than directly mounting to motor shaft, to reduce load on motor gearbox and provide better mechanical advantage.", category: "Arms", difficulty: .intermediate),
                Flashcard(front: "What is a multi-axis arm?", back: "An arm with multiple joints that provides more flexibility but is very difficult to design, manufacture, and control. Generally discouraged for inexperienced teams.", category: "Arms", difficulty: .advanced),
                Flashcard(front: "What are the issues with multi-axis arms?", back: "Accuracy problems, backlash, packaging challenges, and difficulty controlling. Generally not recommended for most teams.", category: "Arms", difficulty: .advanced),
                Flashcard(front: "Can arms be driven by servos?", back: "Yes, servos work well for smaller applications. Motors are needed for larger applications with higher loads.", category: "Arms", difficulty: .intermediate),
                Flashcard(front: "What does software control help with for arms?", back: "Software control helps reduce load on motor gearboxes by implementing limits, acceleration, and position control.", category: "Arms", difficulty: .intermediate),
                Flashcard(front: "What is the typical extension limit for single-axis arms?", back: "Approximately 16 inches, limited by the 18\" x 18\" x 18\" starting size constraint.", category: "Arms", difficulty: .beginner),
                Flashcard(front: "What is the advantage of pivot extension over single-axis arms?", back: "Pivot extension provides longer reach (24-36\" or more) by combining arm rotation with linear extension.", category: "Arms", difficulty: .intermediate)
            ]
        ),
        
        // 5. Programming Fundamentals
        FlashcardDeck(
            title: "Programming Fundamentals",
            description: "FTC programming concepts, OpModes, and basics",
            category: .programming,
            icon: "laptopcomputer",
            flashcards: [
                Flashcard(front: "What is the difference between OpMode and LinearOpMode?", back: "OpMode uses event-driven programming with init() and loop() methods. LinearOpMode uses sequential programming with waitForStart() and is easier for beginners.", category: "Programming", difficulty: .beginner),
                Flashcard(front: "What is the autonomous period?", back: "The first 30 seconds of a match where the robot operates without driver control, running pre-programmed routines.", category: "Programming", difficulty: .beginner),
                Flashcard(front: "What is the TeleOp period?", back: "The driver-controlled period (typically 2 minutes) where drivers control the robot using gamepads.", category: "Programming", difficulty: .beginner),
                Flashcard(front: "What is the Hardware Map?", back: "A configuration file that maps hardware devices (motors, servos, sensors) to code variables, allowing code to access hardware.", category: "Programming", difficulty: .beginner),
                Flashcard(front: "What is Blocks programming?", back: "Visual drag-and-drop programming for FTC, ideal for beginners. Easier to learn but less flexible than Java.", category: "Programming", difficulty: .beginner),
                Flashcard(front: "What is Java programming?", back: "Text-based programming for FTC, more flexible and powerful than Blocks. Industry standard but steeper learning curve.", category: "Programming", difficulty: .beginner),
                Flashcard(front: "What does the FTC SDK provide?", back: "Comprehensive libraries for motors, servos, sensors, and gamepads, making it easier to program robots effectively.", category: "Programming", difficulty: .beginner),
                Flashcard(front: "What is Android Studio?", back: "The development environment used for FTC programming. Download from developer.android.com and install FTC SDK plugin.", category: "Programming", difficulty: .beginner),
                Flashcard(front: "What is the Robot Controller?", back: "The device that runs robot code - either embedded in a Control Hub or running on a separate Android phone.", category: "Programming", difficulty: .beginner),
                Flashcard(front: "What is the Driver Station?", back: "The device that provides the driver interface, allowing drivers to control the robot using gamepads.", category: "Programming", difficulty: .beginner),
                Flashcard(front: "How do Robot Controller and Driver Station communicate?", back: "Via WiFi or WiFi Direct. Both devices must be on the same network or use WiFi Direct for direct connection.", category: "Programming", difficulty: .intermediate),
                Flashcard(front: "What is the first step in creating an OpMode?", back: "Configure the Hardware Map - add all motors, servos, and sensors to the configuration file.", category: "Programming", difficulty: .beginner)
            ]
        ),
        
        // 6. Control Systems & Sensors
        FlashcardDeck(
            title: "Control Systems & Sensors",
            description: "Encoders, IMU, PID control, and feedback systems",
            category: .programming,
            icon: "sensor.tag.radiowaves.forward",
            flashcards: [
                Flashcard(front: "What does an encoder measure?", back: "An encoder measures the position and velocity of a motor, providing feedback for precise control.", category: "Sensors", difficulty: .intermediate),
                Flashcard(front: "What is an IMU?", back: "Inertial Measurement Unit - a sensor that measures orientation (pitch, roll, yaw), acceleration, and angular velocity, used for navigation.", category: "Sensors", difficulty: .intermediate),
                Flashcard(front: "What is PID control?", back: "Proportional-Integral-Derivative control - a feedback control system that uses error to adjust output for precise positioning or speed control.", category: "Control Systems", difficulty: .advanced),
                Flashcard(front: "What does the P in PID stand for?", back: "Proportional - responds to current error. Higher P values respond more strongly to error.", category: "Control Systems", difficulty: .advanced),
                Flashcard(front: "What does the I in PID stand for?", back: "Integral - responds to accumulated error over time. Helps eliminate steady-state error.", category: "Control Systems", difficulty: .advanced),
                Flashcard(front: "What does the D in PID stand for?", back: "Derivative - responds to rate of change of error. Helps reduce overshoot and oscillations.", category: "Control Systems", difficulty: .advanced),
                Flashcard(front: "What is a finite state machine?", back: "A programming pattern that organizes robot behavior into discrete states, making complex behaviors manageable and easier to debug.", category: "Control Systems", difficulty: .intermediate),
                Flashcard(front: "What is a color sensor?", back: "A sensor that detects colors, used to identify colored game elements or follow colored tape on the field.", category: "Sensors", difficulty: .beginner),
                Flashcard(front: "What is a distance sensor?", back: "A sensor that measures distance to objects, used to detect walls, obstacles, or game elements.", category: "Sensors", difficulty: .beginner),
                Flashcard(front: "What is a touch sensor?", back: "A sensor that detects physical contact, used to detect when robot touches game elements or field features.", category: "Sensors", difficulty: .beginner),
                Flashcard(front: "What is sensor fusion?", back: "Combining data from multiple sensors (like IMU + encoders) for better accuracy and reliability than using sensors individually.", category: "Control Systems", difficulty: .advanced),
                Flashcard(front: "How do you calibrate an IMU?", back: "Initialize the IMU and follow calibration procedures before each match. Calibration ensures accurate orientation readings.", category: "Sensors", difficulty: .intermediate),
                Flashcard(front: "What is odometry?", back: "Precise position tracking using wheel encoders or odometry wheels, enabling accurate navigation and path following.", category: "Control Systems", difficulty: .advanced),
                Flashcard(front: "What is feedforward control?", back: "Predicting required motor power based on desired motion, reducing error by anticipating needs rather than just reacting to error.", category: "Control Systems", difficulty: .advanced)
            ]
        ),
        
        // 7. Autonomous Programming
        FlashcardDeck(
            title: "Autonomous Programming",
            description: "Path planning, odometry, vision, and autonomous strategies",
            category: .programming,
            icon: "brain.head.profile",
            flashcards: [
                Flashcard(front: "How long is the autonomous period?", back: "30 seconds. The robot operates without driver control during this time.", category: "Autonomous", difficulty: .beginner),
                Flashcard(front: "What is path planning?", back: "Determining robot paths to reach targets during autonomous. Planning the route the robot will take.", category: "Autonomous", difficulty: .intermediate),
                Flashcard(front: "What is odometry used for in autonomous?", back: "Tracking robot position on the field, enabling precise navigation to target locations.", category: "Autonomous", difficulty: .advanced),
                Flashcard(front: "What is computer vision?", back: "Using cameras to detect and track game elements autonomously, enabling robots to make decisions based on what they see.", category: "Autonomous", difficulty: .advanced),
                Flashcard(front: "What libraries are used for computer vision?", back: "OpenCV, TensorFlow Lite, or EasyOpenCV. These libraries process camera images to detect objects.", category: "Autonomous", difficulty: .advanced),
                Flashcard(front: "Why should you program multiple autonomous routines?", back: "For different starting positions and game scenarios. Having multiple routines allows adaptation to match situations.", category: "Autonomous", difficulty: .intermediate),
                Flashcard(front: "What is kinematics?", back: "Mathematical models of robot motion used for accurate path planning and predicting robot position.", category: "Autonomous", difficulty: .advanced),
                Flashcard(front: "What should you test in autonomous?", back: "Test consistency - does the routine work the same every time? Identify failure points and refine based on results.", category: "Autonomous", difficulty: .intermediate),
                Flashcard(front: "What are decision points in autonomous?", back: "Points where sensor data determines which action the robot takes. Example: If vision detects element on left, go left.", category: "Autonomous", difficulty: .intermediate),
                Flashcard(front: "What are fallback behaviors?", back: "Backup behaviors if sensors fail or don't detect expected conditions. Ensures robot still completes some actions even if sensors fail.", category: "Autonomous", difficulty: .intermediate),
                Flashcard(front: "What is path following?", back: "Using odometry to follow planned paths accurately, enabling precise navigation along predetermined routes.", category: "Autonomous", difficulty: .advanced)
            ]
        ),
        
        // 8. TeleOp Optimization
        FlashcardDeck(
            title: "TeleOp Optimization",
            description: "Gamepad control, smooth movement, and driver experience",
            category: .programming,
            icon: "gamecontroller.fill",
            flashcards: [
                Flashcard(front: "What is a dead zone?", back: "A small range of gamepad input that is ignored to prevent drift. Prevents robot from moving when gamepad is centered but slightly off.", category: "TeleOp", difficulty: .intermediate),
                Flashcard(front: "What is input scaling?", back: "Transforming gamepad input using exponential or logarithmic scaling for fine control. Allows precise control at low speeds.", category: "TeleOp", difficulty: .intermediate),
                Flashcard(front: "What is acceleration/deceleration?", back: "Gradually changing motor power instead of instantly changing, providing smooth movement instead of jerky motion.", category: "TeleOp", difficulty: .intermediate),
                Flashcard(front: "Why should you test with actual drivers?", back: "Drivers can provide feedback on control mapping and robot behavior. Get driver input to optimize controls.", category: "TeleOp", difficulty: .beginner),
                Flashcard(front: "What is gamepad rumble?", back: "Haptic feedback through gamepad vibration, used to provide driver feedback about robot state or events.", category: "TeleOp", difficulty: .intermediate),
                Flashcard(front: "What is telemetry?", back: "Displaying sensor values and robot state on the Driver Station screen, used for debugging and driver feedback.", category: "TeleOp", difficulty: .beginner),
                Flashcard(front: "How do you organize mechanism states?", back: "Use state machines to organize mechanism states (intake on/off, arm up/down), making control logic clearer.", category: "TeleOp", difficulty: .intermediate),
                Flashcard(front: "What are safety limits?", back: "Code that prevents mechanisms from exceeding safe ranges, protecting mechanisms from damage.", category: "TeleOp", difficulty: .intermediate),
                Flashcard(front: "Why coordinate mechanisms?", back: "Ensure mechanisms work together smoothly. For example, don't try to intake while arm is in wrong position.", category: "TeleOp", difficulty: .intermediate)
            ]
        ),
        
        // 9. Electronics & Control Systems
        FlashcardDeck(
            title: "Electronics & Control Systems",
            description: "Control Hub, motors, servos, and system architecture",
            category: .technical,
            icon: "cpu.fill",
            flashcards: [
                Flashcard(front: "What is the Control Hub?", back: "The REV Control Hub is the main robot controller that runs robot code and connects to motors, servos, and sensors.", category: "Electronics", difficulty: .beginner),
                Flashcard(front: "What is an Expansion Hub?", back: "An additional hub that provides more motor and servo ports, used when you need more ports than the Control Hub provides.", category: "Electronics", difficulty: .beginner),
                Flashcard(front: "What voltage do FTC motors use?", back: "12 volts DC. FTC motors are 12V DC motors with integrated gearboxes.", category: "Electronics", difficulty: .beginner),
                Flashcard(front: "What is free speed?", back: "The maximum RPM of a motor with no load. Higher free speed means the motor can spin faster.", category: "Electronics", difficulty: .intermediate),
                Flashcard(front: "What is stall torque?", back: "The maximum torque a motor can produce when stopped (stalled). Higher stall torque means more powerful motor.", category: "Electronics", difficulty: .intermediate),
                Flashcard(front: "What wire gauge should you use for motors?", back: "18 AWG wire. Thicker wire handles motor current better than thinner wire.", category: "Electronics", difficulty: .beginner),
                Flashcard(front: "What wire gauge should you use for servos?", back: "22 AWG wire. Thinner wire is sufficient for servo current which is lower than motor current.", category: "Electronics", difficulty: .beginner),
                Flashcard(front: "What is a servo?", back: "A device that provides precise angular positioning for mechanisms requiring accuracy rather than high power.", category: "Electronics", difficulty: .beginner),
                Flashcard(front: "What rotation range do most servos have?", back: "180 degrees. Some servos rotate 270° or 360°, but 180° is most common.", category: "Electronics", difficulty: .beginner),
                Flashcard(front: "What is PWM?", back: "Pulse-Width Modulation - the signal method used to control servos. Servos use PWM signals for precise positioning.", category: "Electronics", difficulty: .intermediate),
                Flashcard(front: "What is the difference between metal-gear and plastic-gear servos?", back: "Metal-gear servos are more durable and last longer, but are more expensive. Plastic-gear servos are cheaper but less durable.", category: "Electronics", difficulty: .beginner),
                Flashcard(front: "What is the REV Driver Hub?", back: "A purpose-built device for the Driver Station, more reliable than Android phones with better battery life.", category: "Electronics", difficulty: .beginner),
                Flashcard(front: "How many motor ports does a Control Hub have?", back: "4 motor ports. Use Expansion Hubs if you need more than 4 motors.", category: "Electronics", difficulty: .beginner),
                Flashcard(front: "How many servo ports does a Control Hub have?", back: "6 servo ports. Use Expansion Hubs if you need more than 6 servos.", category: "Electronics", difficulty: .beginner)
            ]
        ),
        
        // 10. Wiring & Electrical Safety
        FlashcardDeck(
            title: "Wiring & Electrical Safety",
            description: "Wire selection, connectors, cable management, and safety",
            category: .technical,
            icon: "bolt.fill",
            flashcards: [
                Flashcard(front: "What wire gauge for motors?", back: "18 AWG wire for motors. Thicker wire handles higher motor current.", category: "Wiring", difficulty: .beginner),
                Flashcard(front: "What wire gauge for servos?", back: "22 AWG wire for servos. Thinner wire sufficient for lower servo current.", category: "Wiring", difficulty: .beginner),
                Flashcard(front: "What wire gauge for sensors?", back: "22-24 AWG wire for sensors. Thin wire sufficient for low current sensor signals.", category: "Wiring", difficulty: .beginner),
                Flashcard(front: "What is strain relief?", back: "Securing cables at connection points to prevent cables from breaking due to movement or pulling.", category: "Wiring", difficulty: .intermediate),
                Flashcard(front: "Why is cable management important?", back: "Prevents cables from getting caught, damaged, or interfering with mechanisms. Improves reliability and maintainability.", category: "Wiring", difficulty: .beginner),
                Flashcard(front: "What is crimping?", back: "The process of securing wire connectors to wires using a crimping tool. Ensures secure electrical connections.", category: "Wiring", difficulty: .intermediate),
                Flashcard(front: "What should you do before working on robot electronics?", back: "Always disconnect the battery. Never work on electronics with battery connected to prevent shocks or shorts.", category: "Safety", difficulty: .beginner),
                Flashcard(front: "What is a short circuit?", back: "When electrical current takes an unintended path, often causing damage or safety hazards. Use fuses to protect against shorts.", category: "Safety", difficulty: .intermediate),
                Flashcard(front: "What is cable bundling?", back: "Organizing cables together using cable ties or sleeves to keep wiring neat and prevent tangling.", category: "Wiring", difficulty: .beginner),
                Flashcard(front: "Why leave slack in cables?", back: "Allow cable movement without strain. Cables without slack can break at connection points when mechanisms move.", category: "Wiring", difficulty: .intermediate),
                Flashcard(front: "What should you check before each match?", back: "Inspect wiring for wear or damage. Check all connections are tight and secure.", category: "Safety", difficulty: .beginner)
            ]
        ),
        
        // 11. Team Management
        FlashcardDeck(
            title: "Team Management",
            description: "Team organization, roles, and structure",
            category: .strategy,
            icon: "person.3.fill",
            flashcards: [
                Flashcard(front: "What is the typical team size for FTC?", back: "5-15 members. Balance skills and interests when recruiting team members.", category: "Team Management", difficulty: .beginner),
                Flashcard(front: "What are functional squads?", back: "Teams organized into groups: design, mechanical, software, outreach. Maintains focus while enabling collaboration.", category: "Team Management", difficulty: .beginner),
                Flashcard(front: "What is a school team?", back: "A team sponsored by a school, using school facilities and oversight. Common team structure.", category: "Team Management", difficulty: .beginner),
                Flashcard(front: "What is a home team?", back: "An independent team using home or community facilities with parent oversight. More flexible but requires more resources.", category: "Team Management", difficulty: .beginner),
                Flashcard(front: "What is a community team?", back: "A team sponsored by an organization (like a library or community center), using organization facilities.", category: "Team Management", difficulty: .beginner),
                Flashcard(front: "What should team leadership structure include?", back: "Team captain, squad leaders, and defined roles and responsibilities for all team members.", category: "Team Management", difficulty: .beginner),
                Flashcard(front: "What communication systems should teams use?", back: "Regular meetings, online platforms (Slack, Discord), and documentation for decisions and changes.", category: "Team Management", difficulty: .beginner),
                Flashcard(front: "What are team goals?", back: "Season goals, competition goals, and individual development goals. Helps focus team efforts.", category: "Team Management", difficulty: .beginner),
                Flashcard(front: "What is a mentor?", back: "An adult advisor who provides guidance, technical expertise, and support to the team. Essential for team success.", category: "Team Management", difficulty: .beginner),
                Flashcard(front: "What types of mentors do teams need?", back: "Technical mentors (engineering, programming) and business mentors (fundraising, management).", category: "Team Management", difficulty: .beginner),
                Flashcard(front: "What is team culture?", back: "The values, expectations, and code of conduct that guide team behavior and interactions.", category: "Team Management", difficulty: .beginner)
            ]
        ),
        
        // 12. Outreach & Community Engagement
        FlashcardDeck(
            title: "Outreach & Community Engagement",
            description: "Outreach activities, community impact, and FIRST values",
            category: .strategy,
            icon: "heart.fill",
            flashcards: [
                Flashcard(front: "Why is outreach important?", back: "Core to FIRST values (Gracious Professionalism, Coopertition), essential for awards, builds community support, and develops team members.", category: "Outreach", difficulty: .beginner),
                Flashcard(front: "What is the Connect Award?", back: "An award recognizing teams for strong community engagement and outreach impact.", category: "Outreach", difficulty: .beginner),
                Flashcard(front: "What are educational workshops?", back: "Teaching robotics to younger students, demonstrating the robot, and inspiring interest in STEM.", category: "Outreach", difficulty: .beginner),
                Flashcard(front: "What is mentoring?", back: "Helping other teams (FLL teams, other FTC teams) or tutoring students. Demonstrates team values and impact.", category: "Outreach", difficulty: .beginner),
                Flashcard(front: "What is community service?", back: "Volunteering at events or helping with community projects. Shows team commitment to community.", category: "Outreach", difficulty: .beginner),
                Flashcard(front: "What should you document for outreach?", back: "Date, location, attendance numbers, activities performed, feedback received, and impact stories.", category: "Outreach", difficulty: .beginner),
                Flashcard(front: "When should teams do outreach?", back: "Throughout the season, not just before competition. Consistent outreach shows genuine commitment.", category: "Outreach", difficulty: .beginner),
                Flashcard(front: "What is Gracious Professionalism?", back: "A FIRST value emphasizing respect, kindness, and helping others while competing. Outreach demonstrates this value.", category: "Outreach", difficulty: .beginner),
                Flashcard(front: "What is Coopertition?", back: "A FIRST value combining cooperation and competition - helping others while competing. Outreach demonstrates this value.", category: "Outreach", difficulty: .beginner),
                Flashcard(front: "What should outreach presentations include?", back: "Team introduction, robot demonstration, FIRST values explanation, and ways to get involved.", category: "Outreach", difficulty: .intermediate)
            ]
        ),
        
        // 13. Competition Strategy
        FlashcardDeck(
            title: "Competition Strategy",
            description: "Game analysis, scouting, and alliance selection",
            category: .strategy,
            icon: "target",
            flashcards: [
                Flashcard(front: "What is scouting?", back: "Collecting data about opponent robots: capabilities, performance metrics, reliability. Used for strategy and alliance selection.", category: "Strategy", difficulty: .beginner),
                Flashcard(front: "What should you analyze in the game manual?", back: "All rules, scoring opportunities, point values, difficulty, field layout, obstacles, and scoring locations.", category: "Strategy", difficulty: .beginner),
                Flashcard(front: "What is a primary strategy?", back: "The main approach for typical match scenarios. The strategy you plan to use most often.", category: "Strategy", difficulty: .intermediate),
                Flashcard(front: "What is an alternative strategy?", back: "A backup plan for different scenarios. Having alternatives allows adaptation to match situations.", category: "Strategy", difficulty: .intermediate),
                Flashcard(front: "What is alliance selection?", back: "The process where top teams select partners for elimination matches. Strategic selection is crucial for success.", category: "Strategy", difficulty: .beginner),
                Flashcard(front: "What makes a good alliance partner?", back: "Complementary capabilities, reliable performance, and teams that work well together.", category: "Strategy", difficulty: .intermediate),
                Flashcard(front: "What is high-value action?", back: "Actions that score many points or provide strategic advantages. Focus robot capabilities on high-value actions.", category: "Strategy", difficulty: .intermediate),
                Flashcard(front: "Why develop multiple strategies?", back: "Different scenarios require different approaches. Having multiple strategies allows adaptation to match situations.", category: "Strategy", difficulty: .intermediate),
                Flashcard(front: "What should you consider in alliance selection?", back: "Complementary capabilities, reliable performance, team dynamics, and how well alliance will work together.", category: "Strategy", difficulty: .intermediate),
                Flashcard(front: "What is strategy adaptation?", back: "Modifying strategies based on competition results. Continuously analyze and adapt strategies throughout season.", category: "Strategy", difficulty: .intermediate)
            ]
        ),
        
        // 14. Awards & Judging
        FlashcardDeck(
            title: "Awards & Judging",
            description: "Award categories, Engineering Portfolio, and presentation",
            category: .strategy,
            icon: "trophy.fill",
            flashcards: [
                Flashcard(front: "What is the Inspire Award?", back: "The highest honor in FTC, recognizing overall excellence in engineering, outreach, and team values.", category: "Awards", difficulty: .beginner),
                Flashcard(front: "What is the Think Award?", back: "An award recognizing engineering excellence, design process, and innovation.", category: "Awards", difficulty: .beginner),
                Flashcard(front: "What is the Connect Award?", back: "An award recognizing community engagement and outreach impact.", category: "Awards", difficulty: .beginner),
                Flashcard(front: "What is the Control Award?", back: "An award recognizing programming excellence and autonomous performance.", category: "Awards", difficulty: .beginner),
                Flashcard(front: "What is the Design Award?", back: "An award recognizing mechanical design excellence and engineering notebook quality.", category: "Awards", difficulty: .beginner),
                Flashcard(front: "What is the Motivate Award?", back: "An award recognizing team spirit and Gracious Professionalism.", category: "Awards", difficulty: .beginner),
                Flashcard(front: "What is an Engineering Portfolio?", back: "Comprehensive documentation of design process, outreach activities, and team values. Required for award consideration.", category: "Awards", difficulty: .beginner),
                Flashcard(front: "How long is the award presentation?", back: "5 minutes. Teams present to judges covering key topics in limited time.", category: "Awards", difficulty: .beginner),
                Flashcard(front: "What is pit judging?", back: "When judges visit the pit to see the robot, ask questions, and review documentation.", category: "Awards", difficulty: .beginner),
                Flashcard(front: "What should the Engineering Portfolio include?", back: "Design process documentation, outreach activities and impact, team values examples, and clear organization.", category: "Awards", difficulty: .intermediate),
                Flashcard(front: "What should award presentations demonstrate?", back: "Strong documentation, clear presentations, demonstrated impact, and alignment with FIRST values.", category: "Awards", difficulty: .intermediate)
            ]
        ),
        
        // 15. Game Manual & Rules
        FlashcardDeck(
            title: "Game Manual & Rules",
            description: "Understanding game rules, Part 1 and Part 2",
            category: .rules,
            icon: "book.fill",
            flashcards: [
                Flashcard(front: "What is Part 1 of the game manual?", back: "Game Rules - contains all game play rules, scoring, field setup, and match procedures.", category: "Rules", difficulty: .beginner),
                Flashcard(front: "What is Part 2 of the game manual?", back: "Robot Rules - contains all robot constraints, inspection requirements, and robot specifications.", category: "Rules", difficulty: .beginner),
                Flashcard(front: "What is the starting size constraint?", back: "Robots must fit completely within 18\" x 18\" x 18\" volume at inspection and before match start.", category: "Rules", difficulty: .beginner),
                Flashcard(front: "What is the weight limit for robots?", back: "42 pounds maximum. Robots must stay under 42 pounds including all mechanisms and batteries.", category: "Rules", difficulty: .beginner),
                Flashcard(front: "Why is rule understanding important?", back: "Rule violations can result in penalties, disqualification, or missed opportunities. Understanding rules affects robot design and strategy.", category: "Rules", difficulty: .beginner),
                Flashcard(front: "What are rule clarifications?", back: "Official updates to rules issued by FIRST throughout the season. Teams must stay updated on clarifications.", category: "Rules", difficulty: .beginner),
                Flashcard(front: "What is robot inspection?", back: "The process where officials verify robots meet all rules and safety requirements before competition.", category: "Rules", difficulty: .beginner),
                Flashcard(front: "What happens if you miss a rule update?", back: "Can result in rule violations or missed opportunities. Teams should check for updates regularly.", category: "Rules", difficulty: .beginner),
                Flashcard(front: "What should you create from the game manual?", back: "Rule summaries organized by category, inspection checklists, and quick reference guides for competition day.", category: "Rules", difficulty: .intermediate),
                Flashcard(front: "How often should you review rules?", back: "Continuously throughout the season. Don't just read once - review regularly and stay updated.", category: "Rules", difficulty: .beginner)
            ]
        ),
        
        // 16. Competition Preparation
        FlashcardDeck(
            title: "Competition Preparation",
            description: "Pre-competition checklists, packing, and pit setup",
            category: .parts,
            icon: "checklist",
            flashcards: [
                Flashcard(front: "What should you check 1-2 weeks before competition?", back: "Robot inspection compliance, battery charging, controller pairing, practice matches, spare parts inventory, and tools organization.", category: "Preparation", difficulty: .beginner),
                Flashcard(front: "What should you pack for competition?", back: "Robot, batteries and chargers, controllers, tools, spare parts, documentation, team supplies, and first aid kit.", category: "Preparation", difficulty: .beginner),
                Flashcard(front: "What is pit setup?", back: "Organizing workspace at competition: clean organized area, tools accessible, spare parts labeled, documentation ready.", category: "Preparation", difficulty: .beginner),
                Flashcard(front: "What should you test before competition?", back: "Everything - robot functions, tools, spare parts, communication, and practice under competition conditions.", category: "Preparation", difficulty: .beginner),
                Flashcard(front: "What is the competition day timeline?", back: "Arrival → Check-in → Pit setup → Robot inspection → Practice matches → Qualification matches → Alliance selection → Elimination matches → Awards.", category: "Preparation", difficulty: .beginner),
                Flashcard(front: "Why arrive early to competition?", back: "Allows time for setup, check-in, pit organization, and addressing any issues before matches begin.", category: "Preparation", difficulty: .beginner),
                Flashcard(front: "What spare parts should you bring?", back: "Common failure parts: motors, servos, fasteners, wires, sensors, and any custom parts that might break.", category: "Preparation", difficulty: .beginner),
                Flashcard(front: "What should you practice before competition?", back: "Practice matches, common repairs, troubleshooting procedures, and team coordination.", category: "Preparation", difficulty: .beginner),
                Flashcard(front: "What should you document before competition?", back: "Maintenance log, repair procedures, troubleshooting guides, and robot configuration.", category: "Preparation", difficulty: .intermediate),
                Flashcard(front: "What is a contingency plan?", back: "Backup plans for common problems. Having contingencies reduces stress and enables quick problem solving.", category: "Preparation", difficulty: .intermediate)
            ]
        ),
        
        // 17. Custom Manufacturing
        FlashcardDeck(
            title: "Custom Manufacturing",
            description: "3D printing, machining, laser cutting, and part legality",
            category: .parts,
            icon: "printer.fill",
            flashcards: [
                Flashcard(front: "What is 3D printing?", back: "Additive manufacturing that builds parts layer by layer. Best for rapid prototyping, custom parts, and complex geometries.", category: "Manufacturing", difficulty: .beginner),
                Flashcard(front: "What materials are used for 3D printing?", back: "PLA (easy to print), PETG (stronger), ABS (durable), TPU (flexible). Choose based on part requirements.", category: "Manufacturing", difficulty: .intermediate),
                Flashcard(front: "What is machining?", back: "Subtractive manufacturing that removes material to create parts. Best for precise metal parts and high strength requirements.", category: "Manufacturing", difficulty: .intermediate),
                Flashcard(front: "What is laser cutting?", back: "Uses laser to cut or engrave materials. Best for flat parts, precise cuts, and various materials like wood, acrylic, cardboard.", category: "Manufacturing", difficulty: .intermediate),
                Flashcard(front: "What is infill percentage?", back: "The percentage of solid material inside a 3D printed part. Higher infill = stronger but heavier and slower to print.", category: "Manufacturing", difficulty: .intermediate),
                Flashcard(front: "What is kerf in laser cutting?", back: "The width of material removed by the laser. Must account for kerf in design to get correct final dimensions.", category: "Manufacturing", difficulty: .intermediate),
                Flashcard(front: "What materials can be laser cut?", back: "Wood, acrylic, cardboard, some plastics, and thin metals. Material choice depends on laser power and safety.", category: "Manufacturing", difficulty: .intermediate),
                Flashcard(front: "What is part legality?", back: "Ensuring custom parts comply with FTC rules (Part 2 of game manual). Parts must meet material and source requirements.", category: "Manufacturing", difficulty: .beginner),
                Flashcard(front: "What safety equipment is needed for machining?", back: "Safety glasses, proper workpiece securing, correct speeds, and following all machine safety procedures.", category: "Manufacturing", difficulty: .intermediate),
                Flashcard(front: "What should you start with in manufacturing?", back: "Simple projects to build manufacturing capabilities gradually. Start with basic parts before complex geometries.", category: "Manufacturing", difficulty: .beginner)
            ]
        ),
        
        // 18. Hardware Components & Parts
        FlashcardDeck(
            title: "Hardware Components & Parts",
            description: "Kit systems, part selection, and fasteners",
            category: .parts,
            icon: "wrench.and.screwdriver.fill",
            flashcards: [
                Flashcard(front: "What is goBILDA?", back: "A modular building system for FTC robots. Easy assembly, good documentation, wide variety of parts.", category: "Hardware", difficulty: .beginner),
                Flashcard(front: "What is REV Robotics?", back: "Manufacturer of control systems and robot parts. Excellent control system, good parts, good support.", category: "Hardware", difficulty: .beginner),
                Flashcard(front: "What is TETRIX?", back: "A building system with durable parts, good for structural applications. Heavier but very durable.", category: "Hardware", difficulty: .beginner),
                Flashcard(front: "What should you consider when selecting parts?", back: "Function requirements, load capacity, weight constraints, cost, and availability.", category: "Hardware", difficulty: .beginner),
                Flashcard(front: "What is part compatibility?", back: "Ensuring parts from different kits work together. Some kits use different fastener sizes or mounting patterns.", category: "Hardware", difficulty: .intermediate),
                Flashcard(front: "What are fasteners?", back: "Hardware used to join parts: screws, bolts, nuts, washers. Different kits may use different fastener sizes.", category: "Hardware", difficulty: .beginner),
                Flashcard(front: "What tools are needed for FTC?", back: "Wrenches, screwdrivers, hex keys, pliers, wire cutters, crimping tools, and measuring tools.", category: "Hardware", difficulty: .beginner),
                Flashcard(front: "What is lead time?", back: "The time between ordering parts and receiving them. Order parts early to account for lead time.", category: "Hardware", difficulty: .beginner),
                Flashcard(front: "Why test parts before finalizing design?", back: "Verify parts meet requirements, work together, and perform as expected. Testing prevents design issues.", category: "Hardware", difficulty: .intermediate)
            ]
        ),
        
        // 19. Troubleshooting & Maintenance
        FlashcardDeck(
            title: "Troubleshooting & Maintenance",
            description: "Problem solving, maintenance schedules, and repairs",
            category: .parts,
            icon: "wrench.and.screwdriver",
            flashcards: [
                Flashcard(front: "What is the troubleshooting process?", back: "1. Identify problem, 2. Analyze problem, 3. Apply solution. Start with simplest solutions first.", category: "Troubleshooting", difficulty: .beginner),
                Flashcard(front: "What is preventive maintenance?", back: "Regular maintenance to prevent problems before they occur. Includes inspections, lubrication, and part replacement.", category: "Maintenance", difficulty: .beginner),
                Flashcard(front: "What should you check daily during competition?", back: "Visual inspection, test basic functions, check battery charge, and clean robot.", category: "Maintenance", difficulty: .beginner),
                Flashcard(front: "What should you check weekly during season?", back: "Detailed inspection of all systems, test all functions, check fasteners, and lubricate moving parts.", category: "Maintenance", difficulty: .beginner),
                Flashcard(front: "What is a maintenance log?", back: "Documentation of maintenance activities, repairs, and part replacements. Helps track robot history and predict failures.", category: "Maintenance", difficulty: .intermediate),
                Flashcard(front: "What is predictive maintenance?", back: "Replacing parts before they fail based on usage patterns. Prevents failures during competition.", category: "Maintenance", difficulty: .advanced),
                Flashcard(front: "What are common robot issues?", back: "Motor not working, servo not moving, sensor not reading, communication lost, robot drifts, mechanism breaks.", category: "Troubleshooting", difficulty: .beginner),
                Flashcard(front: "What should you check if motor doesn't work?", back: "Wiring, power, code, hardware map configuration, and mechanical binding.", category: "Troubleshooting", difficulty: .beginner),
                Flashcard(front: "What should you check if communication is lost?", back: "WiFi connection, network settings, restart both devices, and check for interference.", category: "Troubleshooting", difficulty: .intermediate),
                Flashcard(front: "Why practice repairs before competition?", back: "Practice enables quick repairs during competition. Know how to fix common problems quickly.", category: "Maintenance", difficulty: .beginner)
            ]
        ),
        
        // 20. Design Principles & Best Practices
        FlashcardDeck(
            title: "Design Principles & Best Practices",
            description: "Design tradeoffs, reliability, and best practices",
            category: .technical,
            icon: "star.fill",
            flashcards: [
                Flashcard(front: "What is the reliability principle?", back: "Prioritize reliability over complexity. A simple mechanism that works consistently outperforms a complex one that fails.", category: "Design", difficulty: .beginner),
                Flashcard(front: "What is the speed vs. torque tradeoff?", back: "Higher gear ratios provide more torque but less speed. Lower ratios provide more speed but less torque.", category: "Design", difficulty: .beginner),
                Flashcard(front: "What is the complexity vs. reliability tradeoff?", back: "Simple designs are generally more reliable. Complex designs have more failure points.", category: "Design", difficulty: .beginner),
                Flashcard(front: "What is the weight vs. strength tradeoff?", back: "Stronger materials are typically heavier. Must balance strength requirements with weight budget.", category: "Design", difficulty: .beginner),
                Flashcard(front: "What is the precision vs. speed tradeoff?", back: "More precise mechanisms are often slower. Fast mechanisms are often less precise.", category: "Design", difficulty: .beginner),
                Flashcard(front: "Why prototype early?", back: "Real-world testing reveals issues that theory misses. Prototyping early allows time for iteration and improvement.", category: "Design", difficulty: .beginner),
                Flashcard(front: "Why document design decisions?", back: "Documentation supports learning, troubleshooting, competition judging, and knowledge transfer to future team members.", category: "Design", difficulty: .beginner),
                Flashcard(front: "What is modularity?", back: "Designing systems as separate modules that can be easily repaired or replaced. Improves maintainability.", category: "Design", difficulty: .intermediate),
                Flashcard(front: "What is weight management?", back: "Continuously tracking and optimizing robot weight to stay under 42-pound limit. Critical for competition compliance.", category: "Design", difficulty: .beginner),
                Flashcard(front: "What is a safety margin?", back: "Designing mechanisms to handle loads greater than expected (typically 1.5-2x). Prevents failures under dynamic loads.", category: "Design", difficulty: .intermediate),
                Flashcard(front: "Why test under competition conditions?", back: "Competition is never ideal. Testing under realistic conditions (time pressure, field conditions) reveals real issues.", category: "Design", difficulty: .intermediate),
                Flashcard(front: "What is iterative design?", back: "Designing, building, testing, and improving in cycles. Iteration based on testing leads to better designs.", category: "Design", difficulty: .intermediate)
            ]
        ),
        
        // 21. Vision & Computer Vision
        FlashcardDeck(
            title: "Vision & Computer Vision",
            description: "Camera systems, object detection, and vision processing",
            category: .programming,
            icon: "camera.fill",
            flashcards: [
                Flashcard(front: "What is EasyOpenCV?", back: "A simplified OpenCV library for FTC that makes computer vision more accessible. Easier to use than raw OpenCV.", category: "Vision", difficulty: .intermediate),
                Flashcard(front: "What is TensorFlow Lite?", back: "A machine learning framework for mobile devices. Used for object detection and recognition in FTC.", category: "Vision", difficulty: .advanced),
                Flashcard(front: "What is Vuforia?", back: "A vision library that can track visual targets and provide robot positioning. Used for navigation and object tracking.", category: "Vision", difficulty: .advanced),
                Flashcard(front: "What is AprilTag detection?", back: "Detecting AprilTag markers on the field for precise robot positioning. Provides accurate location data.", category: "Vision", difficulty: .advanced),
                Flashcard(front: "What is color thresholding?", back: "A vision technique that identifies pixels within a specific color range. Used to detect colored game elements.", category: "Vision", difficulty: .intermediate),
                Flashcard(front: "What is contour detection?", back: "Finding the boundaries of objects in an image. Used to identify and locate game elements.", category: "Vision", difficulty: .intermediate),
                Flashcard(front: "What is blob detection?", back: "Identifying regions of similar pixels in an image. Used to find game elements based on color or brightness.", category: "Vision", difficulty: .intermediate),
                Flashcard(front: "What lighting conditions affect vision?", back: "Brightness, shadows, reflections, and color temperature. Vision works best in consistent lighting.", category: "Vision", difficulty: .intermediate),
                Flashcard(front: "What is camera calibration?", back: "Adjusting camera settings to account for distortion and ensure accurate measurements. Improves vision accuracy.", category: "Vision", difficulty: .advanced),
                Flashcard(front: "What is frame rate in vision?", back: "How many images the camera processes per second. Higher frame rates provide more responsive vision but use more processing power.", category: "Vision", difficulty: .intermediate),
                Flashcard(front: "What is image resolution?", back: "The number of pixels in an image. Higher resolution provides more detail but requires more processing.", category: "Vision", difficulty: .intermediate),
                Flashcard(front: "What is region of interest (ROI)?", back: "A specific area of the image to analyze. Reduces processing time by focusing on relevant areas.", category: "Vision", difficulty: .intermediate)
            ]
        ),
        
        // 22. Advanced Programming Concepts
        FlashcardDeck(
            title: "Advanced Programming Concepts",
            description: "Advanced Java, algorithms, and programming patterns",
            category: .programming,
            icon: "chevron.left.forwardslash.chevron.right",
            flashcards: [
                Flashcard(front: "What is a class in Java?", back: "A blueprint for creating objects. Defines properties (variables) and behaviors (methods) that objects will have.", category: "Programming", difficulty: .intermediate),
                Flashcard(front: "What is an object in Java?", back: "An instance of a class. Objects have their own set of properties and can call methods defined in the class.", category: "Programming", difficulty: .intermediate),
                Flashcard(front: "What is inheritance?", back: "A mechanism where a class inherits properties and methods from another class. Promotes code reuse.", category: "Programming", difficulty: .advanced),
                Flashcard(front: "What is polymorphism?", back: "The ability of objects to take multiple forms. Same method can behave differently for different objects.", category: "Programming", difficulty: .advanced),
                Flashcard(front: "What is encapsulation?", back: "Bundling data and methods together in a class, hiding internal details. Promotes better code organization.", category: "Programming", difficulty: .advanced),
                Flashcard(front: "What is a method?", back: "A function defined in a class that performs a specific action. Methods can take parameters and return values.", category: "Programming", difficulty: .beginner),
                Flashcard(front: "What is a variable?", back: "A container that stores data. Variables have a type (int, double, String) and a name.", category: "Programming", difficulty: .beginner),
                Flashcard(front: "What is an array?", back: "A collection of elements of the same type. Arrays have a fixed size and elements are accessed by index.", category: "Programming", difficulty: .intermediate),
                Flashcard(front: "What is a loop?", back: "A control structure that repeats code. Common loops: for, while, do-while.", category: "Programming", difficulty: .beginner),
                Flashcard(front: "What is a conditional statement?", back: "Code that executes based on a condition. if, else if, else, and switch statements.", category: "Programming", difficulty: .beginner),
                Flashcard(front: "What is a boolean?", back: "A data type that can only be true or false. Used for conditions and flags.", category: "Programming", difficulty: .beginner),
                Flashcard(front: "What is debugging?", back: "The process of finding and fixing errors in code. Use telemetry, print statements, and step-through debugging.", category: "Programming", difficulty: .beginner),
                Flashcard(front: "What is code commenting?", back: "Adding explanatory text in code that doesn't execute. Helps others understand code and documents decisions.", category: "Programming", difficulty: .beginner),
                Flashcard(front: "What is code organization?", back: "Structuring code logically with clear methods, classes, and files. Makes code easier to understand and maintain.", category: "Programming", difficulty: .intermediate)
            ]
        ),
        
        // 23. Game Strategy & Analysis
        FlashcardDeck(
            title: "Game Strategy & Analysis",
            description: "Game analysis, scoring strategies, and match planning",
            category: .strategy,
            icon: "chart.bar.fill",
            flashcards: [
                Flashcard(front: "What is point efficiency?", back: "Maximizing points scored per unit of time. Focus on actions that score the most points in the least time.", category: "Strategy", difficulty: .intermediate),
                Flashcard(front: "What is cycle time?", back: "The time to complete one full cycle of an action (collect, score, return). Shorter cycle times mean more scoring opportunities.", category: "Strategy", difficulty: .intermediate),
                Flashcard(front: "What is endgame strategy?", back: "The plan for the final 30 seconds of TeleOp. Often includes high-value actions like hanging or special scoring.", category: "Strategy", difficulty: .intermediate),
                Flashcard(front: "What is autonomous strategy?", back: "The plan for the 30-second autonomous period. Focus on reliable, high-value actions that work consistently.", category: "Strategy", difficulty: .intermediate),
                Flashcard(front: "What is defensive strategy?", back: "Preventing opponents from scoring. Can be effective but must balance with offensive scoring.", category: "Strategy", difficulty: .intermediate),
                Flashcard(front: "What is offensive strategy?", back: "Focusing on maximizing your own scoring. Generally more effective than pure defense.", category: "Strategy", difficulty: .intermediate),
                Flashcard(front: "What is alliance strategy?", back: "Coordinating with alliance partners to maximize combined score. Communication and coordination are key.", category: "Strategy", difficulty: .intermediate),
                Flashcard(front: "What is match planning?", back: "Planning actions for each phase of the match. Autonomous plan, TeleOp plan, and endgame plan.", category: "Strategy", difficulty: .intermediate),
                Flashcard(front: "What is risk vs. reward?", back: "Evaluating whether high-risk, high-reward actions are worth attempting. Consider success rate and point value.", category: "Strategy", difficulty: .intermediate),
                Flashcard(front: "What is consistency in strategy?", back: "Performing actions reliably every match. Consistent strategies are more valuable than unreliable high-risk strategies.", category: "Strategy", difficulty: .intermediate),
                Flashcard(front: "What is adaptation?", back: "Modifying strategy based on match conditions. Adapt to field conditions, opponent behavior, and alliance partner capabilities.", category: "Strategy", difficulty: .intermediate),
                Flashcard(front: "What is scouting data used for?", back: "Identifying opponent capabilities, predicting match outcomes, and making alliance selection decisions.", category: "Strategy", difficulty: .intermediate)
            ]
        ),
        
        // 24. Sensors & Feedback Systems
        FlashcardDeck(
            title: "Sensors & Feedback Systems",
            description: "Sensor types, calibration, and feedback loops",
            category: .programming,
            icon: "sensor.tag.radiowaves.forward.fill",
            flashcards: [
                Flashcard(front: "What is a touch sensor?", back: "A sensor that detects physical contact. Returns true when pressed, false when not pressed.", category: "Sensors", difficulty: .beginner),
                Flashcard(front: "What is a color sensor?", back: "A sensor that detects colors (red, green, blue, alpha). Used to identify colored game elements or follow lines.", category: "Sensors", difficulty: .beginner),
                Flashcard(front: "What is a distance sensor?", back: "A sensor that measures distance to objects. Common types: ultrasonic, time-of-flight, infrared.", category: "Sensors", difficulty: .beginner),
                Flashcard(front: "What is an ultrasonic sensor?", back: "A distance sensor that uses sound waves to measure distance. Good range but can be affected by angle and material.", category: "Sensors", difficulty: .intermediate),
                Flashcard(front: "What is a time-of-flight sensor?", back: "A distance sensor that uses light to measure distance. More accurate than ultrasonic but shorter range.", category: "Sensors", difficulty: .intermediate),
                Flashcard(front: "What is a limit switch?", back: "A mechanical switch that detects when a mechanism reaches a limit. Prevents over-travel and provides position feedback.", category: "Sensors", difficulty: .intermediate),
                Flashcard(front: "What is sensor calibration?", back: "Adjusting sensor readings to account for environmental conditions. Ensures accurate measurements.", category: "Sensors", difficulty: .intermediate),
                Flashcard(front: "What is sensor filtering?", back: "Smoothing sensor readings to reduce noise. Moving averages and low-pass filters are common techniques.", category: "Sensors", difficulty: .advanced),
                Flashcard(front: "What is a potentiometer?", back: "A sensor that measures rotation angle. Used to measure arm or mechanism position.", category: "Sensors", difficulty: .intermediate),
                Flashcard(front: "What is sensor fusion?", back: "Combining data from multiple sensors for better accuracy. Example: IMU + encoders for better position tracking.", category: "Sensors", difficulty: .advanced),
                Flashcard(front: "What is dead reckoning?", back: "Estimating position using encoders and IMU without external references. Less accurate than vision but more reliable.", category: "Sensors", difficulty: .advanced),
                Flashcard(front: "What is sensor latency?", back: "The delay between when something happens and when the sensor detects it. Lower latency means more responsive control.", category: "Sensors", difficulty: .intermediate)
            ]
        ),
        
        // 25. Motor Control & Power Management
        FlashcardDeck(
            title: "Motor Control & Power Management",
            description: "Motor types, power management, and efficiency",
            category: .technical,
            icon: "bolt.car.fill",
            flashcards: [
                Flashcard(front: "What is a DC motor?", back: "A motor that runs on direct current. FTC motors are 12V DC motors with integrated gearboxes.", category: "Motors", difficulty: .beginner),
                Flashcard(front: "What is a servo motor?", back: "A motor with precise position control. Used for mechanisms requiring accurate angular positioning.", category: "Motors", difficulty: .beginner),
                Flashcard(front: "What is motor power?", back: "The voltage applied to a motor, typically -1.0 to 1.0. Positive values rotate one direction, negative the other.", category: "Motors", difficulty: .beginner),
                Flashcard(front: "What is motor velocity?", back: "The speed at which a motor rotates, measured in encoder counts per second or RPM.", category: "Motors", difficulty: .intermediate),
                Flashcard(front: "What is motor position?", back: "The current angle or position of a motor, measured in encoder counts.", category: "Motors", difficulty: .intermediate),
                Flashcard(front: "What is RUN_TO_POSITION mode?", back: "A motor mode where the motor runs until it reaches a target position. Used for precise positioning.", category: "Motors", difficulty: .intermediate),
                Flashcard(front: "What is RUN_USING_ENCODER mode?", back: "A motor mode that uses encoders for velocity control. Provides consistent speed regardless of load.", category: "Motors", difficulty: .intermediate),
                Flashcard(front: "What is RUN_WITHOUT_ENCODER mode?", back: "A motor mode that directly controls power without encoder feedback. Simpler but less precise.", category: "Motors", difficulty: .beginner),
                Flashcard(front: "What is motor braking?", back: "Using motor resistance to slow down. BRAKE mode provides resistance, FLOAT mode allows free rotation.", category: "Motors", difficulty: .intermediate),
                Flashcard(front: "What is power efficiency?", back: "Maximizing robot performance while minimizing battery drain. Important for maintaining power throughout matches.", category: "Motors", difficulty: .intermediate),
                Flashcard(front: "What is current draw?", back: "The amount of electrical current a motor uses. Higher current draw drains battery faster.", category: "Motors", difficulty: .intermediate),
                Flashcard(front: "What is stall current?", back: "The maximum current a motor draws when stopped (stalled). Motors draw most current when stalled.", category: "Motors", difficulty: .intermediate),
                Flashcard(front: "What is free current?", back: "The current a motor draws when spinning with no load. Lower than stall current.", category: "Motors", difficulty: .intermediate),
                Flashcard(front: "What is battery voltage?", back: "The electrical potential of the battery. FTC batteries are 12V nominal, but voltage drops as battery drains.", category: "Motors", difficulty: .beginner)
            ]
        ),
        
        // 26. Autonomous Navigation
        FlashcardDeck(
            title: "Autonomous Navigation",
            description: "Path planning, odometry, and precise movement",
            category: .programming,
            icon: "map.fill",
            flashcards: [
                Flashcard(front: "What is field-centric drive?", back: "Driving relative to the field rather than the robot. Forward always means toward opponent side, regardless of robot orientation.", category: "Navigation", difficulty: .advanced),
                Flashcard(front: "What is robot-centric drive?", back: "Driving relative to the robot. Forward means robot's front, regardless of field orientation.", category: "Navigation", difficulty: .beginner),
                Flashcard(front: "What is odometry?", back: "Precise position tracking using wheel encoders. Provides accurate robot position on the field.", category: "Navigation", difficulty: .advanced),
                Flashcard(front: "What are odometry wheels?", back: "Special wheels used solely for position tracking. Not driven, just roll along to measure movement.", category: "Navigation", difficulty: .advanced),
                Flashcard(front: "What is forward kinematics?", back: "Calculating robot position based on wheel movements. Predicts where robot will be based on encoder readings.", category: "Navigation", difficulty: .advanced),
                Flashcard(front: "What is inverse kinematics?", back: "Calculating required wheel movements to reach a target position. Determines motor commands to reach goals.", category: "Navigation", difficulty: .advanced),
                Flashcard(front: "What is a waypoint?", back: "A point along a path that the robot should pass through. Waypoints define the route to a destination.", category: "Navigation", difficulty: .intermediate),
                Flashcard(front: "What is path smoothing?", back: "Creating smooth curves between waypoints instead of sharp turns. Reduces jerk and improves movement quality.", category: "Navigation", difficulty: .advanced),
                Flashcard(front: "What is trajectory following?", back: "Following a pre-planned path with specific velocity and acceleration profiles. Provides smooth, predictable movement.", category: "Navigation", difficulty: .advanced),
                Flashcard(front: "What is localization?", back: "Determining robot position on the field. Uses sensors (odometry, vision, IMU) to know where robot is.", category: "Navigation", difficulty: .advanced),
                Flashcard(front: "What is pose estimation?", back: "Estimating robot position (x, y) and orientation (heading). Combines multiple sensors for accurate pose.", category: "Navigation", difficulty: .advanced),
                Flashcard(front: "What is a coordinate system?", back: "A system for defining positions. Common: origin at corner, x-axis along one side, y-axis along adjacent side.", category: "Navigation", difficulty: .intermediate)
            ]
        ),
        
        // 27. Competition Day Tips
        FlashcardDeck(
            title: "Competition Day Tips",
            description: "Competition logistics, pit management, and match preparation",
            category: .strategy,
            icon: "calendar.badge.clock",
            flashcards: [
                Flashcard(front: "What should you do when arriving at competition?", back: "Check in, find your pit, set up workspace, and verify robot functionality. Arrive early to allow time for setup.", category: "Competition", difficulty: .beginner),
                Flashcard(front: "What is robot inspection?", back: "Officials verify robot meets all rules: size, weight, safety, and part legality. Must pass before competing.", category: "Competition", difficulty: .beginner),
                Flashcard(front: "What should you bring to the field?", back: "Robot, batteries, controllers, and any tools needed for quick fixes. Keep essentials accessible.", category: "Competition", difficulty: .beginner),
                Flashcard(front: "What is a practice match?", back: "A non-scored match before qualification matches. Use to test robot and get familiar with field.", category: "Competition", difficulty: .beginner),
                Flashcard(front: "What should you do between matches?", back: "Charge batteries, inspect robot, make repairs, review strategy, and prepare for next match.", category: "Competition", difficulty: .beginner),
                Flashcard(front: "What is alliance selection?", back: "Top teams select partners for elimination matches. Strategic selection is crucial for success.", category: "Competition", difficulty: .beginner),
                Flashcard(front: "What should you do during elimination matches?", back: "Coordinate with alliance partners, execute strategy, adapt to match conditions, and communicate effectively.", category: "Competition", difficulty: .intermediate),
                Flashcard(front: "What is a timeout?", back: "A brief pause teams can request during matches. Use for repairs or strategy adjustments.", category: "Competition", difficulty: .beginner),
                Flashcard(front: "What should you do if robot breaks during match?", back: "Stay calm, assess problem, make quick fix if possible, or use timeout if needed. Practice repairs beforehand.", category: "Competition", difficulty: .intermediate),
                Flashcard(front: "What is driver practice?", back: "Practicing driving and operating robot before matches. Improves driver skill and robot familiarity.", category: "Competition", difficulty: .beginner),
                Flashcard(front: "What should you communicate to alliance partners?", back: "Robot capabilities, strategy, and coordination needs. Clear communication improves alliance performance.", category: "Competition", difficulty: .intermediate),
                Flashcard(front: "What is gracious professionalism?", back: "A FIRST value: compete hard but treat everyone with respect and kindness. Help others when possible.", category: "Competition", difficulty: .beginner)
            ]
        ),
        
        // 28. Mechanical Design Principles
        FlashcardDeck(
            title: "Mechanical Design Principles",
            description: "Design fundamentals, materials, and construction",
            category: .technical,
            icon: "hammer.fill",
            flashcards: [
                Flashcard(front: "What is structural rigidity?", back: "Resistance to bending or deformation under load. Important for maintaining accuracy and preventing failures.", category: "Design", difficulty: .intermediate),
                Flashcard(front: "What is moment of inertia?", back: "Resistance to rotational acceleration. Higher moment of inertia means harder to start/stop rotation.", category: "Design", difficulty: .advanced),
                Flashcard(front: "What is stress concentration?", back: "Areas where stress is higher than average. Sharp corners and holes create stress concentrations that can cause failures.", category: "Design", difficulty: .advanced),
                Flashcard(front: "What is a bearing?", back: "A component that reduces friction in rotating parts. Allows smooth rotation with minimal resistance.", category: "Design", difficulty: .intermediate),
                Flashcard(front: "What is backlash?", back: "Play or clearance in gear systems. Causes position inaccuracy and should be minimized.", category: "Design", difficulty: .intermediate),
                Flashcard(front: "What is belt tension?", back: "The tightness of a belt drive system. Proper tension prevents slipping while avoiding excessive wear.", category: "Design", difficulty: .intermediate),
                Flashcard(front: "What is chain tension?", back: "The tightness of a chain drive system. Proper tension ensures smooth power transmission.", category: "Design", difficulty: .intermediate),
                Flashcard(front: "What is a keyway?", back: "A slot in a shaft that prevents rotation between shaft and hub. Ensures components rotate together.", category: "Design", difficulty: .advanced),
                Flashcard(front: "What is a set screw?", back: "A screw that secures components to shafts by pressing against the shaft. Common fastening method.", category: "Design", difficulty: .beginner),
                Flashcard(front: "What is thread locking?", back: "Using threadlocker (like Loctite) to prevent screws from loosening. Important for vibration-prone applications.", category: "Design", difficulty: .intermediate),
                Flashcard(front: "What is material selection?", back: "Choosing appropriate materials based on requirements: strength, weight, cost, and manufacturability.", category: "Design", difficulty: .intermediate),
                Flashcard(front: "What is tolerance?", back: "The acceptable variation in dimensions. Tighter tolerances mean more precise parts but higher cost.", category: "Design", difficulty: .intermediate),
                Flashcard(front: "What is clearance?", back: "The gap between moving parts. Adequate clearance prevents binding while minimizing play.", category: "Design", difficulty: .intermediate),
                Flashcard(front: "What is interference fit?", back: "When parts are sized so one must be forced into the other. Creates tight connection without fasteners.", category: "Design", difficulty: .advanced)
            ]
        ),
        
        // 29. Software Architecture
        FlashcardDeck(
            title: "Software Architecture",
            description: "Code organization, patterns, and best practices",
            category: .programming,
            icon: "square.stack.3d.up.fill",
            flashcards: [
                Flashcard(front: "What is code modularity?", back: "Organizing code into separate, reusable modules. Makes code easier to understand, test, and maintain.", category: "Programming", difficulty: .intermediate),
                Flashcard(front: "What is a state machine?", back: "A programming pattern that organizes behavior into discrete states. Each state has specific behaviors and transitions.", category: "Programming", difficulty: .intermediate),
                Flashcard(front: "What is a subsystem?", back: "A separate system within the robot (drivetrain, intake, arm). Organizing code by subsystem improves structure.", category: "Programming", difficulty: .intermediate),
                Flashcard(front: "What is command-based programming?", back: "A pattern where actions are encapsulated as commands. Commands can be queued and executed sequentially.", category: "Programming", difficulty: .advanced),
                Flashcard(front: "What is a singleton?", back: "A design pattern where only one instance of a class exists. Useful for shared resources like hardware map.", category: "Programming", difficulty: .advanced),
                Flashcard(front: "What is dependency injection?", back: "Passing dependencies (like hardware) into classes rather than accessing globally. Improves testability.", category: "Programming", difficulty: .advanced),
                Flashcard(front: "What is code documentation?", back: "Comments and documentation explaining what code does and why. Essential for team collaboration.", category: "Programming", difficulty: .beginner),
                Flashcard(front: "What is version control?", back: "Tracking changes to code over time. Git is commonly used. Enables collaboration and rollback.", category: "Programming", difficulty: .intermediate),
                Flashcard(front: "What is code review?", back: "Having others examine code before using it. Catches errors and improves code quality.", category: "Programming", difficulty: .intermediate),
                Flashcard(front: "What is refactoring?", back: "Improving code structure without changing functionality. Makes code cleaner and easier to maintain.", category: "Programming", difficulty: .intermediate),
                Flashcard(front: "What is a constant?", back: "A value that doesn't change. Use constants for magic numbers to make code more readable.", category: "Programming", difficulty: .beginner),
                Flashcard(front: "What is code reuse?", back: "Using the same code in multiple places. Reduces duplication and makes maintenance easier.", category: "Programming", difficulty: .intermediate)
            ]
        ),
        
        // 30. Advanced Mechanical Systems
        FlashcardDeck(
            title: "Advanced Mechanical Systems",
            description: "Complex mechanisms, transmissions, and actuation",
            category: .technical,
            icon: "gearshape.2",
            flashcards: [
                Flashcard(front: "What is a differential?", back: "A mechanism that allows wheels on the same axle to rotate at different speeds. Enables smooth turning.", category: "Mechanical", difficulty: .advanced),
                Flashcard(front: "What is a gear train?", back: "Multiple gears connected to transfer power and change speed/torque. Can achieve high gear ratios.", category: "Mechanical", difficulty: .intermediate),
                Flashcard(front: "What is a planetary gearbox?", back: "A compact gearbox with high gear ratios. Common in FTC motors for space-efficient power transmission.", category: "Mechanical", difficulty: .advanced),
                Flashcard(front: "What is a belt drive?", back: "Using belts and pulleys to transfer power. Quieter than gears, allows flexible layouts, but can slip.", category: "Mechanical", difficulty: .intermediate),
                Flashcard(front: "What is a chain drive?", back: "Using chains and sprockets to transfer power. More reliable than belts, allows longer distances, but requires tensioning.", category: "Mechanical", difficulty: .intermediate),
                Flashcard(front: "What is a worm gear?", back: "A gear that provides very high reduction ratios and self-locking. Prevents back-driving but is less efficient.", category: "Mechanical", difficulty: .advanced),
                Flashcard(front: "What is a rack and pinion?", back: "Converting rotational motion to linear motion. Pinion (gear) rotates, rack (bar) moves linearly.", category: "Mechanical", difficulty: .intermediate),
                Flashcard(front: "What is a lead screw?", back: "A threaded rod that converts rotation to linear motion. Provides precise positioning and self-locking.", category: "Mechanical", difficulty: .intermediate),
                Flashcard(front: "What is a four-bar linkage?", back: "A mechanism with four bars connected by joints. Can create complex motion paths from simple rotation.", category: "Mechanical", difficulty: .advanced),
                Flashcard(front: "What is a cam?", back: "A rotating component that creates specific motion patterns. Used to convert rotation to complex motion.", category: "Mechanical", difficulty: .advanced),
                Flashcard(front: "What is a clutch?", back: "A mechanism that can engage or disengage power transmission. Allows selective power transfer.", category: "Mechanical", difficulty: .advanced),
                Flashcard(front: "What is mechanical advantage?", back: "The ratio of output force to input force. Higher mechanical advantage means more output force for same input.", category: "Mechanical", difficulty: .intermediate)
            ]
        )
    ]
}

