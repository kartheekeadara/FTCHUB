//
//  LearningModuleData.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

struct LearningModuleData {
    static let allModules: [LearningModule] = [
        // Robot Design & Mechanisms
        LearningModule(
            title: "Robot Design & Mechanisms",
            description: "Master the fundamentals of robot design, drivetrains, linear motion, intakes, and design tradeoffs.",
            category: .technical,
            difficulty: .beginner,
            estimatedTime: 45,
            icon: "gearshape.2.fill",
            sections: [
                LearningSection(
                    title: "Drivetrains & Movement",
                    content: [
                        .conceptCard(ConceptCard(
                            title: "Drivetrain Basics",
                            summary: "The drivetrain is the foundation of robot mobility. Understanding different types helps you choose the right one for your game strategy.",
                            detailedExplanation: """
                            The drivetrain is arguably the most important part of your robot. It determines how your robot moves, turns, and navigates the field. There are several types of drivetrains, each with unique characteristics:
                            
                            **Tank Drive (Skid-Steer)**
                            - Simple and reliable
                            - Good pushing power
                            - Easy to program
                            - Limited maneuverability
                            - Best for: Beginners, games requiring pushing power
                            
                            **Mecanum Drive**
                            - Holonomic movement (forward, backward, sideways, rotation)
                            - Excellent maneuverability
                            - Requires precise control
                            - More complex programming
                            - Best for: Advanced teams, games requiring precise positioning
                            
                            **Swerve Drive**
                            - Independently steerable wheels
                            - Most precise movement
                            - Very complex mechanically and programmatically
                            - Best for: Expert teams with significant resources
                            """,
                            relatedConcepts: ["Linear Motion Systems", "Power Transmission", "Motor Selection"]
                        )),
                        .tutorial(TutorialContent(
                            title: "Building a Tank Drive",
                            steps: [
                                TutorialStep(
                                    title: "Select Your Motors",
                                    content: "Choose motors with appropriate gear ratios. For drivetrains, balanced speed and torque are important. Common choices include 20:1 or 40:1 gear ratios.",
                                    codeExample: "// Motor configuration example\nDcMotor leftMotor = hardwareMap.get(DcMotor.class, \"leftMotor\");\nDcMotor rightMotor = hardwareMap.get(DcMotor.class, \"rightMotor\");"
                                ),
                                TutorialStep(
                                    title: "Mount Motors Securely",
                                    content: "Mount motors to your chassis using proper fasteners. Ensure motors are aligned parallel to each other for straight driving.",
                                    codeExample: nil
                                ),
                                TutorialStep(
                                    title: "Attach Wheels",
                                    content: "Attach wheels to motor shafts. Use set screws or hex hubs. Ensure wheels are the same diameter and properly secured.",
                                    codeExample: nil
                                ),
                                TutorialStep(
                                    title: "Wire and Configure",
                                    content: "Wire motors to your Control Hub. Configure motor directions in your code - one side should be reversed to drive straight forward.",
                                    codeExample: "leftMotor.setDirection(DcMotor.Direction.FORWARD);\nrightMotor.setDirection(DcMotor.Direction.REVERSE);"
                                )
                            ]
                        ))
                    ],
                    quiz: Quiz(
                        title: "Drivetrain Knowledge Quiz",
                        description: "Test your understanding of drivetrain concepts",
                        questions: [
                            QuizQuestion(
                                question: "Which drivetrain type is best for beginners?",
                                type: .multipleChoice,
                                options: ["Tank Drive", "Mecanum Drive", "Swerve Drive", "X-Drive"],
                                correctAnswers: [0],
                                explanation: "Tank drive is the simplest and most reliable option, making it ideal for beginners."
                            ),
                            QuizQuestion(
                                question: "What are the key advantages of Mecanum drive? (Select all that apply)",
                                type: .multipleSelect,
                                options: ["Holonomic movement", "Simple programming", "Excellent maneuverability", "Low cost"],
                                correctAnswers: [0, 2],
                                explanation: "Mecanum drive provides holonomic movement and excellent maneuverability, but requires complex programming and is more expensive."
                            ),
                            QuizQuestion(
                                question: "For a drivetrain, you should prioritize speed over torque.",
                                type: .trueFalse,
                                options: ["True", "False"],
                                correctAnswers: [1],
                                explanation: "Drivetrains need a balance of speed and torque. Too much speed reduces pushing power, while too much torque reduces speed."
                            )
                        ]
                    )
                ),
                LearningSection(
                    title: "Linear Motion Systems",
                    content: [
                        .conceptCard(ConceptCard(
                            title: "Extension Mechanisms",
                            summary: "Linear motion systems allow robots to extend beyond starting size constraints, reaching game elements and scoring locations.",
                            detailedExplanation: """
                            FTC robots start in an 18" x 18" x 18" box, but many games require reaching beyond this constraint. Linear motion systems provide the solution:
                            
                            **Drawer Slides**
                            - Simple and reliable
                            - Good load capacity
                            - Limited extension length
                            - Best for: Short extensions, heavy loads
                            
                            **Extrusion Slides**
                            - Longer extension possible
                            - Good rigidity
                            - Customizable
                            - Best for: Medium extensions, custom applications
                            
                            **Lead Screws**
                            - Precise positioning
                            - Self-locking
                            - Slower than other methods
                            - Best for: Precision applications
                            
                            **Design Considerations:**
                            - Extension length needed (typically >24" preferred)
                            - Load capacity required
                            - Speed requirements
                            - Integration with robot structure
                            """,
                            relatedConcepts: ["Arms & Linkages", "Weight Management", "Structural Design"]
                        )),
                        .codeExample(CodeExample(
                            title: "Linear Slide Control",
                            language: "java",
                            code: """
                            // Linear slide with encoder control
                            DcMotor slideMotor = hardwareMap.get(DcMotor.class, "slideMotor");
                            slideMotor.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
                            
                            // Extend slide
                            public void extendSlide(double power) {
                                slideMotor.setPower(power);
                                // Add limit switch check for safety
                            }
                            
                            // Retract slide
                            public void retractSlide(double power) {
                                slideMotor.setPower(-power);
                            }
                            """,
                            explanation: "This example shows basic linear slide control using encoder feedback. Always include safety checks like limit switches.",
                            lineExplanations: [
                                2: "Set motor to use encoder for position feedback",
                                5: "Extend function with power control",
                                10: "Retract function with negative power"
                            ]
                        ))
                    ]
                ),
                LearningSection(
                    title: "Intakes & Manipulation",
                    content: [
                        .conceptCard(ConceptCard(
                            title: "Intake Design Principles",
                            summary: "Effective intakes are crucial for game piece manipulation. Design considerations include speed, reliability, and adaptability.",
                            detailedExplanation: """
                            Intakes are mechanisms that collect game pieces. Key design principles:
                            
                            **Roller Intakes**
                            - Fast and efficient
                            - Good for spherical objects
                            - Can jam with irregular shapes
                            - Best for: Balls, consistent objects
                            
                            **Finger Intakes**
                            - Gentle handling
                            - Good for fragile objects
                            - Slower than rollers
                            - Best for: Delicate game pieces
                            
                            **Passive Intakes**
                            - No motors required
                            - Simple and reliable
                            - Limited control
                            - Best for: Simple collection tasks
                            
                            **Design Tips:**
                            - Use compliant materials (rubber, foam) for better grip
                            - Design for multiple game piece types if possible
                            - Include sensors to detect when pieces are collected
                            - Test with actual game pieces early and often
                            """,
                            relatedConcepts: ["Mechanism Design", "Sensor Integration", "Game Strategy"]
                        )),
                        .tutorial(TutorialContent(
                            title: "Building a Roller Intake",
                            steps: [
                                TutorialStep(
                                    title: "Select Rollers",
                                    content: "Choose compliant rollers (rubber or foam) that match your game piece size. Common sizes are 1.5\" to 2\" diameter.",
                                    codeExample: nil
                                ),
                                TutorialStep(
                                    title: "Mount Motors",
                                    content: "Mount motors to create opposing roller pairs. Use gear ratios that provide good speed (typically 20:1 or 30:1).",
                                    codeExample: "DcMotor intakeMotor = hardwareMap.get(DcMotor.class, \"intakeMotor\");\nintakeMotor.setDirection(DcMotor.Direction.FORWARD);"
                                ),
                                TutorialStep(
                                    title: "Add Sensors",
                                    content: "Install distance sensors or touch sensors to detect when game pieces are collected. This helps prevent jamming.",
                                    codeExample: "DistanceSensor intakeSensor = hardwareMap.get(DistanceSensor.class, \"intakeSensor\");"
                                ),
                                TutorialStep(
                                    title: "Test and Iterate",
                                    content: "Test with actual game pieces. Adjust roller spacing, speed, and materials based on performance.",
                                    codeExample: nil
                                )
                            ]
                        ))
                    ],
                    quiz: Quiz(
                        title: "Intake Design Quiz",
                        questions: [
                            QuizQuestion(
                                question: "Which intake type is best for fragile game pieces?",
                                type: .multipleChoice,
                                options: ["Roller Intake", "Finger Intake", "Passive Intake", "All are equal"],
                                correctAnswers: [1],
                                explanation: "Finger intakes provide gentle handling, making them ideal for fragile objects."
                            )
                        ]
                    )
                ),
                LearningSection(
                    title: "Arms & Linkages",
                    content: [
                        .conceptCard(ConceptCard(
                            title: "Arm Design Strategies",
                            summary: "Arms extend robot reach and enable scoring. Different designs offer tradeoffs between reach, speed, and complexity.",
                            detailedExplanation: """
                            Arms are essential for reaching game elements. Common designs:
                            
                            **Single-Stage Arms**
                            - Simple and reliable
                            - Limited reach
                            - Fast operation
                            - Best for: Short reach requirements
                            
                            **Multi-Stage Arms**
                            - Extended reach
                            - More complex
                            - Slower operation
                            - Best for: Long reach requirements
                            
                            **Four-Bar Linkages**
                            - Predictable motion
                            - Good for specific paths
                            - Complex design
                            - Best for: Precise positioning
                            
                            **Design Considerations:**
                            - Weight distribution affects stability
                            - Use counterweights or springs to reduce motor load
                            - Consider gravity compensation
                            - Test at full extension to ensure stability
                            """,
                            relatedConcepts: ["Linear Motion", "Weight Management", "Structural Design"]
                        ))
                    ]
                )
            ],
            externalUrl: "https://gm0.org/en/latest/docs/common-mechanisms/"
        ),
        
        // Programming & Software
        LearningModule(
            title: "Programming & Software",
            description: "Learn FTC programming from basics to advanced techniques. Master Blocks, Java, control systems, and autonomous programming.",
            category: .programming,
            difficulty: .intermediate,
            estimatedTime: 60,
            icon: "laptopcomputer",
            sections: [
                LearningSection(
                    title: "Getting Started",
                    content: [
                        .tutorial(TutorialContent(
                            title: "Your First OpMode",
                            steps: [
                                TutorialStep(
                                    title: "Create a New OpMode",
                                    content: "In Android Studio, create a new class that extends OpMode or LinearOpMode. LinearOpMode is recommended for beginners as it's easier to understand.",
                                    codeExample: """
                                    @TeleOp(name = "My First OpMode")
                                    public class MyFirstOpMode extends LinearOpMode {
                                        @Override
                                        public void runOpMode() {
                                            // Your code here
                                        }
                                    }
                                    """
                                ),
                                TutorialStep(
                                    title: "Initialize Hardware",
                                    content: "Use hardwareMap to get references to your motors, servos, and sensors. Always initialize hardware in init() or before waitForStart().",
                                    codeExample: """
                                    DcMotor leftMotor = hardwareMap.get(DcMotor.class, "leftMotor");
                                    DcMotor rightMotor = hardwareMap.get(DcMotor.class, "rightMotor");
                                    """
                                ),
                                TutorialStep(
                                    title: "Control Motors",
                                    content: "Set motor power using setPower() method. Values range from -1.0 (full reverse) to 1.0 (full forward).",
                                    codeExample: """
                                    double power = gamepad1.left_stick_y;
                                    leftMotor.setPower(power);
                                    rightMotor.setPower(power);
                                    """
                                )
                            ]
                        )),
                        .conceptCard(ConceptCard(
                            title: "OpMode vs LinearOpMode",
                            summary: "Understanding the difference between OpMode and LinearOpMode helps you choose the right base class.",
                            detailedExplanation: """
                            **OpMode**
                            - Event-driven programming
                            - init() and loop() methods
                            - More control over timing
                            - Better for advanced teams
                            
                            **LinearOpMode**
                            - Sequential programming
                            - waitForStart() and sequential code
                            - Easier to understand
                            - Better for beginners
                            - Can use sleep() and other blocking operations
                            
                            For most teams, LinearOpMode is recommended as it's more intuitive and easier to debug.
                            """,
                            relatedConcepts: ["Control Systems", "TeleOp Programming", "Autonomous Programming"]
                        ))
                    ],
                    quiz: Quiz(
                        title: "Programming Basics Quiz",
                        questions: [
                            QuizQuestion(
                                question: "Which base class is recommended for beginners?",
                                type: .multipleChoice,
                                options: ["OpMode", "LinearOpMode", "Both are equal", "Neither"],
                                correctAnswers: [1],
                                explanation: "LinearOpMode is recommended for beginners because it uses sequential programming which is easier to understand."
                            ),
                            QuizQuestion(
                                question: "Motor power values range from -1.0 to 1.0",
                                type: .trueFalse,
                                options: ["True", "False"],
                                correctAnswers: [0],
                                explanation: "Motor power is set using values from -1.0 (full reverse) to 1.0 (full forward), with 0.0 being stopped."
                            )
                        ]
                    )
                ),
                LearningSection(
                    title: "Control Systems",
                    content: [
                        .conceptCard(ConceptCard(
                            title: "PID Control",
                            summary: "PID (Proportional-Integral-Derivative) controllers provide precise position and speed control using feedback.",
                            detailedExplanation: """
                            PID control is essential for precise robot movement. It uses three components:
                            
                            **Proportional (P)**
                            - Response proportional to error
                            - Larger error = larger correction
                            - Can cause oscillation if too high
                            
                            **Integral (I)**
                            - Eliminates steady-state error
                            - Accumulates error over time
                            - Can cause overshoot if too high
                            
                            **Derivative (D)**
                            - Reduces oscillation
                            - Responds to rate of change
                            - Helps with stability
                            
                            Tuning PID requires testing and adjustment. Start with P, then add I and D as needed.
                            """,
                            relatedConcepts: ["Encoders", "Motor Control", "Autonomous Programming"]
                        )),
                        .codeExample(CodeExample(
                            title: "Simple PID Controller",
                            language: "java",
                            code: """
                            public class PIDController {
                                private double kP, kI, kD;
                                private double integral = 0;
                                private double lastError = 0;
                                
                                public PIDController(double kP, double kI, double kD) {
                                    this.kP = kP;
                                    this.kI = kI;
                                    this.kD = kD;
                                }
                                
                                public double calculate(double target, double current) {
                                    double error = target - current;
                                    integral += error;
                                    double derivative = error - lastError;
                                    lastError = error;
                                    
                                    return (kP * error) + (kI * integral) + (kD * derivative);
                                }
                            }
                            """,
                            explanation: "A basic PID controller implementation. Tune kP, kI, and kD values through testing.",
                            lineExplanations: [
                                2: "PID constants - tune these values",
                                3: "Integral accumulator",
                                4: "Previous error for derivative calculation",
                                11: "Calculate error (difference from target)",
                                12: "Accumulate error for integral term",
                                13: "Calculate rate of change for derivative",
                                16: "Return PID output (motor power)"
                            ]
                        ))
                    ]
                ),
                LearningSection(
                    title: "Autonomous Programming",
                    content: [
                        .conceptCard(ConceptCard(
                            title: "Autonomous Strategy",
                            summary: "Autonomous periods can make or break a match. Plan carefully and test extensively.",
                            detailedExplanation: """
                            The autonomous period is 30 seconds and happens before driver control. Key strategies:
                            
                            **Scoring First**
                            - Get points on the board early
                            - Can demoralize opponents
                            - Requires reliable mechanisms
                            
                            **Parking**
                            - Simple and reliable
                            - Guaranteed points
                            - Low risk
                            
                            **Complex Routines**
                            - High scoring potential
                            - Higher failure risk
                            - Requires extensive testing
                            
                            **Best Practices:**
                            - Start simple, add complexity gradually
                            - Test on actual field setup
                            - Use encoders for precise movement
                            - Include error recovery
                            - Test under competition conditions
                            """,
                            relatedConcepts: ["PID Control", "Encoders", "Game Strategy"]
                        )),
                        .codeExample(CodeExample(
                            title: "Basic Autonomous Movement",
                            language: "java",
                            code: """
                            @Autonomous(name = "Simple Auto")
                            public class SimpleAuto extends LinearOpMode {
                                private DcMotor leftMotor, rightMotor;
                                
                                @Override
                                public void runOpMode() {
                                    initHardware();
                                    waitForStart();
                                    
                                    // Drive forward for 2 seconds
                                    driveForward(0.5, 2000);
                                    
                                    // Turn 90 degrees
                                    turnRight(0.3, 1000);
                                    
                                    // Stop
                                    stopMotors();
                                }
                                
                                private void driveForward(double power, long timeMs) {
                                    leftMotor.setPower(power);
                                    rightMotor.setPower(power);
                                    sleep(timeMs);
                                }
                            }
                            """,
                            explanation: "A simple autonomous routine that drives forward and turns. Use encoders for more precise control.",
                            lineExplanations: [
                                8: "Initialize hardware before waitForStart()",
                                9: "Wait for start button",
                                12: "Drive forward with 50% power for 2 seconds",
                                15: "Turn right with 30% power for 1 second"
                            ]
                        ))
                    ],
                    quiz: Quiz(
                        title: "Autonomous Programming Quiz",
                        questions: [
                            QuizQuestion(
                                question: "How long is the autonomous period?",
                                type: .multipleChoice,
                                options: ["15 seconds", "30 seconds", "45 seconds", "60 seconds"],
                                correctAnswers: [1],
                                explanation: "The autonomous period is exactly 30 seconds."
                            ),
                            QuizQuestion(
                                question: "Which is recommended for autonomous: simple and reliable or complex and high-scoring?",
                                type: .multipleChoice,
                                options: ["Simple and reliable", "Complex and high-scoring", "Both are equal", "Neither"],
                                correctAnswers: [0],
                                explanation: "Starting simple and reliable is recommended. You can add complexity later once the basics work."
                            )
                        ]
                    )
                ),
                LearningSection(
                    title: "Sensor Integration",
                    content: [
                        .conceptCard(ConceptCard(
                            title: "Common Sensors",
                            summary: "Sensors provide feedback for autonomous control and driver assistance.",
                            detailedExplanation: """
                            **Encoders**
                            - Measure motor rotation
                            - Essential for precise movement
                            - Use for distance and position
                            
                            **IMU (Inertial Measurement Unit)**
                            - Measures orientation
                            - Used for turning and balancing
                            - Provides heading information
                            
                            **Distance Sensors**
                            - Measure distance to objects
                            - Useful for alignment
                            - Can detect game pieces
                            
                            **Color Sensors**
                            - Detect colors
                            - Useful for line following
                            - Can identify game elements
                            
                            **Touch Sensors**
                            - Simple on/off detection
                            - Good for limit switches
                            - Reliable and simple
                            """,
                            relatedConcepts: ["Autonomous Programming", "Control Systems", "Robot Design"]
                        )),
                        .codeExample(CodeExample(
                            title: "Using Encoders for Distance",
                            language: "java",
                            code: """
                            // Configure encoder
                            DcMotor motor = hardwareMap.get(DcMotor.class, "motor");
                            motor.setMode(DcMotor.RunMode.STOP_AND_RESET_ENCODER);
                            motor.setMode(DcMotor.RunMode.RUN_USING_ENCODER);
                            
                            // Drive specific distance
                            int targetPosition = 1000; // encoder ticks
                            motor.setTargetPosition(targetPosition);
                            motor.setMode(DcMotor.RunMode.RUN_TO_POSITION);
                            motor.setPower(0.5);
                            
                            // Wait until done
                            while (motor.isBusy()) {
                                // Optional: Add timeout or other logic
                            }
                            """,
                            explanation: "Using encoders to drive a specific distance. Encoders provide precise position control.",
                            lineExplanations: [
                                3: "Reset encoder to zero",
                                4: "Set mode to use encoder",
                                7: "Set target position in encoder ticks",
                                8: "Set mode to run to position",
                                9: "Set power (lower power = more precise)",
                                12: "Wait until motor reaches target"
                            ]
                        ))
                    ]
                )
            ],
            externalUrl: "https://gm0.org/en/latest/docs/software/"
        ),
        
        // Electronics & Control Systems
        LearningModule(
            title: "Electronics & Control Systems",
            description: "Master FTC electronics: Control Hub, motors, servos, sensors, wiring, and driver station configuration.",
            category: .technical,
            difficulty: .intermediate,
            estimatedTime: 50,
            icon: "cpu.fill",
            sections: [
                LearningSection(
                    title: "Control Hub Setup",
                    content: [
                        .tutorial(TutorialContent(
                            title: "Setting Up Your Control Hub",
                            steps: [
                                TutorialStep(
                                    title: "Unbox and Inspect",
                                    content: "Carefully unbox your Control Hub and inspect for any damage. Check all ports and connectors.",
                                    codeExample: nil
                                ),
                                TutorialStep(
                                    title: "Connect Power",
                                    content: "Connect the battery to the Control Hub using the provided power cable. Ensure proper polarity.",
                                    codeExample: nil
                                ),
                                TutorialStep(
                                    title: "Configure WiFi",
                                    content: "Use the REV Hardware Client app to configure WiFi settings. Connect to your network or use WiFi Direct.",
                                    codeExample: nil
                                ),
                                TutorialStep(
                                    title: "Update Firmware",
                                    content: "Check for firmware updates using the REV Hardware Client. Keep firmware up to date for best performance.",
                                    codeExample: nil
                                )
                            ]
                        ))
                    ],
                    quiz: Quiz(
                        title: "Control Hub Setup Quiz",
                        description: "Test your understanding of Control Hub setup and configuration",
                        questions: [
                            QuizQuestion(
                                question: "What tool do you use to configure the Control Hub?",
                                type: .multipleChoice,
                                options: ["REV Hardware Client app", "Android Studio", "Driver Station", "Robot Controller"],
                                correctAnswers: [0],
                                explanation: "The REV Hardware Client app is used to configure WiFi, update firmware, and manage Control Hub settings."
                            ),
                            QuizQuestion(
                                question: "Which of the following are steps in Control Hub setup? (Select all that apply)",
                                type: .multipleSelect,
                                options: ["Connect power", "Configure WiFi", "Update firmware", "Install Android Studio"],
                                correctAnswers: [0, 1, 2],
                                explanation: "Control Hub setup involves connecting power, configuring WiFi, and updating firmware. Android Studio is for programming, not setup."
                            ),
                            QuizQuestion(
                                question: "You should always check for firmware updates when setting up a new Control Hub.",
                                type: .trueFalse,
                                options: ["True", "False"],
                                correctAnswers: [0],
                                explanation: "Keeping firmware up to date ensures best performance and compatibility with the latest features."
                            )
                        ]
                    )
                ),
                LearningSection(
                    title: "Motors & Servos",
                    content: [
                        .conceptCard(ConceptCard(
                            title: "Motor Selection",
                            summary: "Choosing the right motor and gear ratio is crucial for robot performance.",
                            detailedExplanation: """
                            **Motor Types:**
                            - REV HD Hex Motor: High torque, good for drivetrains
                            - REV Core Hex Motor: Balanced, versatile
                            - TETRIX Motor: Legacy, still common
                            
                            **Gear Ratios:**
                            - 20:1: Balanced speed and torque
                            - 40:1: Higher torque, lower speed
                            - 60:1: Very high torque, very low speed
                            
                            **Servos:**
                            - Position servos: Precise angle control
                            - Continuous rotation: Speed control
                            - Use servos for arms, grippers, and mechanisms requiring precise positioning
                            """,
                            relatedConcepts: ["Robot Design", "Control Systems", "Mechanism Design"]
                        )),
                        .tutorial(TutorialContent(
                            title: "Configuring Motors",
                            steps: [
                                TutorialStep(
                                    title: "Hardware Map Setup",
                                    content: "Configure motor names in the Robot Configuration. Use descriptive names like 'leftMotor' and 'rightMotor'.",
                                    codeExample: nil
                                ),
                                TutorialStep(
                                    title: "Initialize in Code",
                                    content: "Get motor references using hardwareMap. Set motor directions and modes.",
                                    codeExample: "DcMotor motor = hardwareMap.get(DcMotor.class, \"motorName\");\nmotor.setDirection(DcMotor.Direction.FORWARD);"
                                ),
                                TutorialStep(
                                    title: "Set Zero Power Behavior",
                                    content: "Configure what happens when power is zero. BRAKE mode holds position, FLOAT allows free rotation.",
                                    codeExample: "motor.setZeroPowerBehavior(DcMotor.ZeroPowerBehavior.BRAKE);"
                                )
                            ]
                        ))
                    ]
                ),
                LearningSection(
                    title: "Wiring & Safety",
                    content: [
                        .conceptCard(ConceptCard(
                            title: "Electrical Safety",
                            summary: "Proper wiring and safety practices prevent damage and ensure reliable operation.",
                            detailedExplanation: """
                            **Wiring Best Practices:**
                            - Use proper wire gauge (18-22 AWG for motors)
                            - Secure all connections
                            - Route wires away from moving parts
                            - Use wire management (zip ties, channels)
                            
                            **Safety Rules:**
                            - Always disconnect battery when working on robot
                            - Check for exposed wires
                            - Ensure proper polarity
                            - Test with low power first
                            
                            **Common Issues:**
                            - Loose connections cause intermittent problems
                            - Wrong polarity damages components
                            - Overloading circuits causes failures
                            - Poor wire management leads to damage
                            """,
                            relatedConcepts: ["Control Hub Setup", "Troubleshooting", "Competition Preparation"]
                        ))
                    ],
                    quiz: Quiz(
                        title: "Electrical Safety Quiz",
                        questions: [
                            QuizQuestion(
                                question: "What should you do before working on robot wiring?",
                                type: .multipleChoice,
                                options: ["Turn off robot", "Disconnect battery", "Both", "Neither"],
                                correctAnswers: [2],
                                explanation: "Always disconnect the battery before working on wiring to prevent electrical shock and damage."
                            )
                        ]
                    )
                )
            ],
            externalUrl: "https://gm0.org/en/latest/docs/power-and-electronics/"
        )
    ]
}

