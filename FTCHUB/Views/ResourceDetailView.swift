//
//  ResourceDetailView.swift
//  FTCHUB
//
//  Created by Kartheek Eadara on 11/23/25.
//

import SwiftUI

struct ResourceDetailView: View {
    let resource: FTCResource
    @State private var selectedSubPage: ResourceSubPage?
    @State private var showingBrowser = false
    
    private var categoryColor: Color {
        switch resource.category {
        case .official: return .blue
        case .rules: return .purple
        case .community: return .green
        case .technical: return .orange
        case .programming: return .indigo
        case .strategy: return .pink
        case .safety: return .red
        case .awards: return .yellow
        case .video: return .red
        case .parts: return .gray
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(categoryColor.opacity(0.15))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: resource.icon)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(categoryColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(resource.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            Text(resource.category.displayName)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(categoryColor.opacity(0.2))
                                .foregroundColor(categoryColor)
                                .cornerRadius(8)
                        }
                        
                        Spacer()
                    }
                    
                    Text(resource.description)
                        .font(.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.lg)
                
                // Comprehensive Guide Section
                if let explanation = resource.explanation {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Comprehensive Technical Guide")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        ExplanationTextView(text: explanation, categoryColor: categoryColor)
                    }
                    .padding(DesignSystem.Spacing.lg)
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.lg)
                }
                
                // Subpages Section
                if let subPages = resource.subPages, !subPages.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Related Topics & Resources")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        ForEach(subPages) { subPage in
                            NavigationLink(destination: SubPageDetailView(subPage: subPage, categoryColor: categoryColor)) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .font(.title3)
                                        .foregroundColor(categoryColor)
                                        .frame(width: 40)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(subPage.title)
                                            .font(.headline)
                                            .foregroundColor(DesignSystem.Colors.textPrimary)
                                        
                                        Text(subPage.description)
                                            .font(.subheadline)
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                            .lineLimit(2)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                                .padding(DesignSystem.Spacing.md)
                                .background(DesignSystem.Colors.secondaryBackground)
                                .cornerRadius(DesignSystem.CornerRadius.md)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(DesignSystem.Spacing.lg)
                    .background(DesignSystem.Colors.cardBackground)
                    .cornerRadius(DesignSystem.CornerRadius.lg)
                }
                
                // External Link Button
                Button(action: {
                    showingBrowser = true
                }) {
                    HStack {
                        Image(systemName: "safari")
                            .font(.headline)
                        Text("Open Official Resource")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(DesignSystem.Spacing.lg)
                    .frame(maxWidth: .infinity)
                    .background(categoryColor)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
                .padding(.top, DesignSystem.Spacing.sm)
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle(resource.title)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingBrowser) {
            ResourceBrowserView(resource: resource)
        }
    }
}

struct SubPageDetailView: View {
    let subPage: ResourceSubPage
    let categoryColor: Color
    @State private var showingBrowser = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text(subPage.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(subPage.description)
                        .font(.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .padding(DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.lg)
                
                // Technical Content - Comprehensive details for each subpage
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    Text("Comprehensive Technical Guide")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    ExplanationTextView(text: getSubPageContent(for: subPage.title), categoryColor: categoryColor)
                }
                .padding(DesignSystem.Spacing.lg)
                .background(DesignSystem.Colors.cardBackground)
                .cornerRadius(DesignSystem.CornerRadius.lg)
                
                // External Link
                Button(action: {
                    showingBrowser = true
                }) {
                    HStack {
                        Image(systemName: "safari")
                            .font(.headline)
                        Text("Open Resource")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding(DesignSystem.Spacing.lg)
                    .frame(maxWidth: .infinity)
                    .background(categoryColor)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle(subPage.title)
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingBrowser) {
            ResourceBrowserView(resource: FTCResource(
                title: subPage.title,
                description: subPage.description,
                url: subPage.url,
                category: .technical,
                icon: "doc.text.fill"
            ))
        }
    }
    
    private func getSubPageContent(for title: String) -> String {
        // Comprehensive technical content for each subpage
        switch title {
        case "Drivetrains & Movement":
            return """
**Drivetrain Fundamentals:**
The drivetrain is the foundation of robot mobility and one of the most critical design decisions. It determines how your robot moves, how quickly it can change direction, how much pushing power it has, and how precisely it can position itself. Understanding drivetrain options and their tradeoffs is essential for competitive success.

**Tank Drive (Skid-Steer) Systems:**
Tank drive is the simplest and most common drivetrain in FTC. It uses two or four wheels per side, with each side driven independently. To move forward, both sides drive forward. To turn, one side drives while the other stops or reverses. Tank drive provides excellent pushing power, good reliability, simple control, and is easy to build and maintain. However, it has limited maneuverability (cannot move sideways), requires more space to turn, and can cause field damage during sharp turns. Tank drive is ideal for games requiring pushing power, climbing, or when simplicity and reliability are priorities. Power transmission typically uses direct drive, gear reduction, or chain/belt systems. Teams should consider wheel selection (traction vs. speed), gear ratios (speed vs. torque), and weight distribution for optimal performance.

**Mecanum Drive Systems:**
Mecanum drive uses special wheels with rollers at 45° angles, enabling holonomic movement. By controlling wheel speeds independently, the robot can move forward, backward, sideways, diagonally, and rotate simultaneously. Mecanum drive provides excellent maneuverability, precise positioning, and the ability to move in any direction without turning. However, it requires precise control algorithms, is more complex to program, has less pushing power than tank drive, and requires careful wheel alignment. Mecanum drive is ideal for games requiring precise positioning, tight spaces, or complex movement patterns. The control system must account for wheel orientation, calculate proper wheel speeds for desired movement, and handle sensor feedback for accurate positioning. Teams should use encoders on all wheels for precise control and consider IMU for heading control.

**Swerve Drive Systems:**
Swerve drive uses independently steerable wheels, each capable of rotating 360° and driving independently. This provides the most precise movement and positioning capabilities of any drivetrain. Swerve drive enables movement in any direction while maintaining any orientation, provides excellent precision, and allows complex movement patterns. However, it is extremely complex mechanically (requires steering mechanism for each wheel), very complex programmatically (requires coordination of steering and driving), heavy (more components), and expensive. Swerve drive is typically only used by very advanced teams with significant resources and expertise. Implementation requires steering motors, driving motors, encoders for both steering and driving, and sophisticated control algorithms. Teams considering swerve should have strong mechanical and programming capabilities.

**Power Transmission Systems:**
Power transmission transfers motor power to wheels efficiently. Direct drive mounts wheels directly to motor shafts, providing simplicity but limiting gear ratio options. Gear reduction uses gearboxes to reduce speed and increase torque, with common ratios including 3.7:1 (high speed), 5.2:1 (balanced), 13.7:1 (high torque), and 19.2:1 (very high torque). Chain and sprocket systems provide flexible gear ratios, good efficiency, and easy ratio changes, but require proper tensioning and can stretch over time. Belt and pulley systems provide smooth, quiet operation and good efficiency, but have lower torque capacity than chains. Teams should select transmission based on speed requirements, torque requirements, weight constraints, and reliability needs. Proper tensioning, alignment, and maintenance are critical for all transmission systems.

**Wheel Selection and Traction:**
Wheel selection significantly affects drivetrain performance. Traction wheels provide high friction for pushing and climbing but can cause field damage. Omni wheels provide low friction for easier turning but less pushing power. Mecanum wheels provide holonomic movement but require precise control. Wheel diameter affects speed (larger = faster) and torque (larger = less torque for same motor). Wheel width affects traction and stability. Teams should select wheels based on game requirements: need for pushing power (use traction wheels), need for maneuverability (use omni or mecanum), need for speed (use larger diameter), and need for precision (use smaller diameter with encoders). Wheel material and tread pattern also affect performance.

**Control Systems and Programming:**
Effective drivetrain control requires proper programming. Basic tank drive control uses gamepad joysticks directly - left stick controls left side, right stick controls right side. Mecanum drive requires field-oriented or robot-oriented control algorithms that calculate wheel speeds based on desired movement vector. Swerve drive requires complex algorithms coordinating steering angles and wheel speeds. Teams should implement acceleration limiting to prevent sudden movements, use encoders for precise speed control, use IMU for heading control, and tune control parameters through testing. Advanced teams use path planning algorithms, odometry for position tracking, and autonomous movement routines.

**Design Considerations and Best Practices:**
Drivetrain design involves multiple considerations. Weight distribution affects stability and performance - teams should balance weight across drivetrain. Center of gravity affects climbing and stability - lower center of gravity improves stability. Ground clearance affects obstacle navigation - teams should ensure adequate clearance. Wheelbase (distance between wheel axles) affects turning radius and stability - longer wheelbase improves stability but increases turning radius. Teams should prototype drivetrains early, test extensively on competition-like surfaces, measure actual performance (speed, acceleration, turning radius), and iterate based on results. Documentation should include design rationale, performance data, and lessons learned.
"""
            
        case "Linear Motion Systems":
            return """
**Linear Motion Fundamentals:**
Linear motion systems provide extension beyond the robot's starting size constraints (18" x 18" x 18"). In most FTC games, teams need to reach areas the drivetrain cannot access to pick up or deposit game elements. Linear motion is one of the most important components of successful robot design, with most games requiring >18" extension, >24" preferred, and sometimes >36" for specific challenges.

**Drawer Slides:**
Drawer slides are simple, reliable linear extension systems commonly used in FTC. They consist of nested channels that slide relative to each other, providing smooth extension and retraction. Drawer slides offer good load capacity, simple installation, reliable operation, and are readily available. However, they have limited extension length (typically 12-18"), can have play/slop, and may require modification for FTC use. Drawer slides are ideal for shorter extension requirements, applications needing reliability over precision, and teams seeking simple solutions. Teams should select slides with appropriate load ratings, ensure proper mounting to prevent binding, and consider adding stops to prevent over-extension. Drawer slides work well for elevators, lifts, and shorter extension applications.

**Extrusion Slides:**
Extrusion slides use aluminum extrusions (like 8020 or similar) with linear bearings to provide longer extension with good rigidity. They offer longer extension lengths (24-36" or more), excellent rigidity and strength, high customization potential, and good precision. However, they are more expensive, heavier than other options, require more assembly, and need careful alignment. Extrusion slides are ideal for applications requiring longer extension, high load capacity, or precise positioning. Teams can customize extrusion slides with different lengths, add multiple stages for even longer extension, and integrate with other mechanisms. Proper bearing selection, alignment, and lubrication are critical for performance. Extrusion slides work well for long-reach mechanisms, heavy-load applications, and precision positioning systems.

**Linear Bearing Slides:**
Linear bearing slides use precision linear bearings on rails to provide smooth, precise motion. They offer excellent precision and smoothness, high load capacity, good repeatability, and long life. However, they are expensive, require careful alignment, need protection from debris, and are heavier than some alternatives. Linear bearing slides are ideal for applications requiring high precision, smooth operation, or heavy loads. Teams should use proper rail mounting (must be straight and parallel), select appropriate bearing size for loads, protect bearings from debris, and maintain proper lubrication. Linear bearing slides work well for precision positioning, heavy-load applications, and systems requiring smooth operation.

**Lead Screw Systems:**
Lead screws provide linear motion through rotational input, offering precise positioning and self-locking capability. Lead screws convert rotational motion to linear motion with high precision, provide self-locking (hold position without power), offer high load capacity, and enable precise control. However, they are slower than other methods, require more power, can have backlash, and are more expensive. Lead screws are ideal for applications requiring precise positioning, holding position without power, or high load capacity. Teams should select appropriate lead (distance per revolution) based on speed and precision requirements, use anti-backlash nuts when precision is critical, ensure proper alignment, and consider motor power requirements. Lead screws work well for elevators, precision positioning systems, and applications requiring position holding.

**Rack and Pinion Systems:**
Rack and pinion systems use a rotating pinion gear engaging a linear rack to provide linear motion. They offer good speed and extension length, relatively simple design, good efficiency, and flexible implementation. However, they can have backlash, require proper engagement, and need alignment. Rack and pinion systems are ideal for applications requiring longer extension with good speed, moderate precision requirements, or flexible mounting. Teams should ensure proper gear engagement (backlash affects precision), use appropriate gear ratios, maintain alignment, and protect from debris. Rack and pinion works well for long-reach mechanisms, elevators, and systems requiring good speed.

**Rigging and Cable Management:**
Linear motion systems require proper rigging (cables, belts, or chains) to transfer power from motors to moving stages. Cable management is critical for reliability - cables must be routed to avoid interference, protected from pinch points, and organized for maintainability. Teams should use appropriate cable lengths (not too long, not too short), route cables to avoid interference with moving parts, protect cables from sharp edges and pinch points, and organize cables for easy access. Proper rigging ensures smooth operation and prevents failures. Teams should test rigging under expected loads and conditions, use appropriate cable management solutions, and maintain rigging throughout the season.

**Design Considerations:**
Linear motion system design involves multiple considerations. Extension length needed depends on game requirements - teams should measure required reach and add margin. Load capacity must handle expected loads with safety margin - teams should calculate loads and select appropriate systems. Speed requirements affect system selection - faster systems may require different approaches. Integration with other mechanisms affects design - linear motion must work with intakes, outtakes, and other systems. Weight is always a constraint - teams should optimize for weight while meeting requirements. Teams should prototype early, test extension under load, measure actual performance, and iterate based on results. Documentation should include design calculations, performance data, and integration considerations.
"""
            
        case "Intakes & Manipulation":
            return """
**Intake System Fundamentals:**
Intake systems are critical for competitive success - they collect game elements reliably and efficiently, enabling robots to score points. The fundamental principle of effective intake design is "touch it, own it" - when your intake contacts a game element, it should instantly control that element. Understanding intake principles, types, and design considerations is essential for building competitive robots.

**Active Intake Principles:**
Active intakes use rotational motion (wheels, rollers, belts) powered by motors to pull game elements into the robot. They provide fast collection, good reliability when designed properly, and can handle multiple elements. Active intakes require understanding element properties (size, shape, weight, surface texture), collection geometry (how elements enter intake), and speed requirements. The faster the intake, generally the more effective - top teams often use 3.7:1 (1600 RPM) or 5.2:1 (1000 RPM) motors. Intake geometry must guide elements into collection area, prevent elements from escaping, and facilitate transfer to storage or scoring systems. Teams should dedicate at least one motor to intake if possible, test intake designs extensively with actual game elements, and iterate based on results.

**Types of Active Intakes:**
Roller intakes use rotating rollers to pull elements in, providing good speed and reliability. Wheel intakes use compliant wheels (often with high friction) to grip and pull elements, offering excellent grip and speed. Belt intakes use continuous belts to pull elements, providing smooth operation and good capacity. Tube intakes use rotating mechanisms inside tubes to pull elements through, offering compact design and good reliability. Each type has advantages and disadvantages - teams should select based on element properties, space constraints, and reliability requirements. Roller intakes work well for spherical elements, wheel intakes work well for various shapes, belt intakes work well for high-capacity needs, and tube intakes work well for compact applications.

**Passive Intake and Claw Systems:**
Passive intakes and claws use mechanical mechanisms to grasp individual elements without powered collection. They provide precise control, can handle specific element orientations, and are typically simpler than active intakes. However, they are generally slower, require precise positioning, and may struggle with multiple elements. Passive systems work well when elements are in known locations, when precise control is needed, or when simplicity is priority. Claw designs must match element shape, provide secure grip, and enable reliable release. Teams should test passive systems extensively to ensure reliable operation under competition conditions.

**Intake Geometry and Design:**
Intake geometry significantly affects performance. Funnel designs guide elements into collection area, with wider openings for easier collection and narrower sections for secure holding. Roller/wheel spacing must match element size - too wide and elements fall through, too narrow and elements jam. Entry angle affects collection reliability - elements should enter smoothly without bouncing out. Teams should design with margin for error in element orientation and robot alignment. Testing with actual game elements in various orientations is critical - designs that work perfectly in ideal conditions may fail in competition. Iteration based on testing results is essential for effective intake design.

**Material Selection for Intakes:**
Intake materials affect performance and reliability. Compliant materials (rubber, silicone) provide good grip and can conform to element shapes, improving collection reliability. Rigid materials (plastic, metal) provide durability and consistent geometry. Teams often use compliant wheels or rollers for active intakes to improve grip. Material selection should consider element properties (smooth vs. textured surfaces), durability requirements (intakes see significant wear), and weight constraints. Teams should test different materials to find optimal balance between grip, durability, and weight.

**Transfer Systems:**
Transfer systems move elements from intake to storage or scoring mechanisms. They must handle elements reliably, prevent jamming, and integrate smoothly with intake and scoring systems. Common transfer methods include belts, rollers, gravity feeds, and mechanical pushers. Transfer system design must consider element properties, transfer distance, speed requirements, and integration with other systems. Teams should ensure smooth element flow from intake through transfer to scoring, test transfer systems extensively, and design for reliability. Transfer systems often determine overall system reliability - a perfect intake is useless if transfer system fails.

**Manipulation Mechanisms:**
Manipulation mechanisms handle elements after collection - orienting, sorting, or preparing for scoring. They may include rotating mechanisms to change element orientation, sorting mechanisms to separate different elements, or staging mechanisms to prepare elements for scoring. Manipulation mechanisms must be reliable, fast enough for game requirements, and integrate with intake and scoring systems. Design considerations include element properties, required manipulation, speed requirements, and space constraints. Teams should prototype manipulation mechanisms early, test with actual elements, and iterate based on results.

**Integration and System Design:**
Intake systems must integrate with other robot systems. Integration with drivetrain affects collection approach - teams may need to drive into elements or position precisely. Integration with storage affects element flow - elements must move smoothly from intake to storage. Integration with scoring affects overall system - intake must provide elements when scoring system needs them. Teams should design intake as part of complete system, not in isolation. System-level testing ensures all components work together reliably. Teams should test complete intake-to-scoring cycle extensively under competition-like conditions.
"""
            
        case "Arms & Linkages":
            return """
**Arm Design Fundamentals:**
Arms provide extension and flexibility for end effectors, allowing robots to reach beyond their starting size constraints and position mechanisms precisely. Arms encompass a wide variety of mechanisms, from simple single-axis arms to complex multi-axis systems. Understanding arm design principles, types, and applications is essential for building competitive robots that can access game elements and score effectively.

**Arms for Extension:**
Arms can provide extension to reach areas the drivetrain cannot access. Long arms need large reduction ratios to drive effectively - example designs use 254.5:1 reduction. It's recommended to transfer torque to the arm through a gear, chain, or belt rather than directly mounting to motor shaft due to axial forces and the ability to get larger reduction. Due to large momentum these arms can carry, if suddenly stopped they may break a motor's gearbox or even tip the robot over. Software control can help reduce load on motor gearboxes through acceleration limiting and smooth motion profiles. Depending on application and implementation, arms can be either faster or slower than linear extension options.

**Single-Axis Arms:**
Single-axis arms are the simplest type of arm, providing rotation around one axis. They are relatively easy and quick to build, making them good choices for teams with limited experience or time. However, they have little high-level competitive viability as main extension systems since the extension they provide is limited due to starting size constraints (18" x 18" x 18"). Single arms can only provide around 16" of extension, whereas over 24" of extension is desired for most games. Single arms work well for smaller extension requirements, as secondary mechanisms, or for teams learning arm design. They require large reduction ratios for effective operation and must be designed to handle expected loads.

**Pivot Extension Mechanisms:**
Pivot extension combines an arm with linear extension (typically linear slides), allowing the linear extension to provide desired extension length for both horizontal and vertical extension while removing the need for transfer stages. This design provides the extension length of linear systems with the flexibility of arms. Pivot extension allows linear slides to reach horizontally and vertically, providing access to game elements at various heights and positions. This design has been used successfully by many competitive teams, including championship-level robots. Pivot extension requires coordination between arm rotation and linear extension, proper load distribution, and integration with end effectors. Teams should design pivot systems with proper support, smooth motion, and reliable operation.

**Multi-Axis Arms:**
Multi-axis arms consist of multiple rotational joints, providing extension and flexibility that single-axis arms lack. They can position end effectors at various locations and orientations, providing significant flexibility. However, multi-axis arms are much more difficult to design, manufacture, and control. They have issues with accuracy, backlash, packaging, and complexity while providing little benefit over linear slides and other extension methods for most applications. Multi-axis arms are highly discouraged for inexperienced FTC teams due to complexity and difficulty. Advanced teams with significant resources and expertise may use multi-axis arms for specific applications, but most teams should consider simpler alternatives.

**Arms for End Effectors:**
Arms are commonly used to add flexibility and control to end effectors (intakes, outtakes, scoring mechanisms). These arms typically have one or more rotational joints and/or linear extension, allowing end effectors to reach various positions. Due to relatively small power requirements, these arms are often driven by servos instead of motors. Single and multi-axis arms can add control to vertical and horizontal distance of end effectors, allowing intakes to go over barriers and reach down for elements, or outtakes to deposit at various locations. Linear extension on arms increases range of robot's deposit capabilities. Arms for end effectors must be properly supported - end effectors are likely to see collisions, and with arms acting as levers, it's imperative to take extra caution to mount and support servos properly.

**Linkage Mechanisms:**
Linkages provide mechanical advantage and controlled motion through connected rigid members. Four-bar linkages are common in FTC, providing controlled motion paths and mechanical advantage. Linkages can convert rotational motion to linear motion, provide mechanical advantage, and create specific motion paths. Design considerations include link lengths, pivot locations, motion range, and load capacity. Linkages work well for applications requiring specific motion paths, mechanical advantage, or controlled motion. Teams should understand linkage kinematics, design for required motion, and ensure proper support and alignment.

**Design Considerations:**
Arm design involves multiple considerations. Extension length needed depends on game requirements - teams should measure required reach and design accordingly. Load capacity must handle expected loads - arms act as levers, so loads are amplified. Weight distribution affects stability - arms extending far from robot center affect balance. Power requirements depend on loads and speeds - teams should calculate power needs and select appropriate motors or servos. Integration with other systems affects design - arms must work with intakes, outtakes, and scoring mechanisms. Teams should prototype arms early, test under expected loads, measure actual performance, and iterate based on results. Documentation should include design calculations, performance data, and integration considerations.

**Control and Programming:**
Arm control requires proper programming for smooth, reliable operation. Basic control uses direct motor/servo commands, but advanced control uses acceleration limiting, position feedback, and smooth motion profiles. Acceleration limiting prevents sudden movements that can damage mechanisms or tip robots. Position feedback (encoders, potentiometers) enables precise positioning. Smooth motion profiles provide reliable, repeatable operation. Teams should implement proper control algorithms, tune control parameters through testing, and ensure reliable operation under competition conditions. Software control is especially important for arms due to momentum and potential for damage.
"""
            
        case "Design Tradeoffs & Best Practices":
            return """
**Understanding Design Tradeoffs:**
Every design decision in FTC involves tradeoffs - there are no perfect solutions, only optimal balances for specific requirements. Understanding common tradeoffs and how to evaluate them is essential for making informed design decisions. Teams must balance multiple competing factors: performance vs. reliability, complexity vs. simplicity, weight vs. strength, speed vs. precision, and cost vs. capability. Successful teams understand these tradeoffs and make decisions based on game requirements, team capabilities, and strategic priorities.

**Speed vs. Torque Tradeoffs:**
Higher gear ratios provide more torque but less speed, while lower gear ratios provide more speed but less torque. Teams must select gear ratios based on application requirements: mechanisms needing high force (lifting, pushing) require higher ratios, while mechanisms needing high speed (intakes, drivetrains) may use lower ratios. Understanding power requirements and selecting appropriate ratios is critical. Teams should calculate required torque and speed, select appropriate gear ratios, and test to verify performance. Sometimes multiple stages or variable ratios are needed to balance speed and torque requirements.

**Complexity vs. Reliability Tradeoffs:**
Simpler designs are generally more reliable - fewer parts mean fewer failure points, easier troubleshooting, and faster repairs. Complex designs may provide better performance but introduce reliability risks. Teams must balance complexity and reliability based on game requirements and team capabilities. For critical mechanisms (those that must work for robot to function), reliability should be prioritized. For non-critical mechanisms, some complexity may be acceptable for performance gains. Teams should ask: does increased complexity provide sufficient benefit to justify reliability risk? Can we achieve goals with simpler design? What happens if complex mechanism fails?

**Weight vs. Strength Tradeoffs:**
Stronger materials are typically heavier, while lighter materials may have lower strength. Teams must balance weight and strength based on application requirements and overall robot weight constraints (42-pound limit). For high-stress applications (drivetrain, lifting mechanisms), strength is critical and weight may be acceptable. For low-stress applications (covers, non-structural elements), lightweight materials are preferred. Teams should understand material properties, calculate expected stresses, select appropriate materials, and optimize for weight while meeting strength requirements. Sometimes hybrid approaches (strong materials where needed, lightweight elsewhere) provide optimal balance.

**Precision vs. Speed Tradeoffs:**
More precise mechanisms are often slower, while faster mechanisms may sacrifice precision. Teams must balance precision and speed based on game requirements. For applications requiring precise positioning (scoring mechanisms), precision is critical and speed may be acceptable. For applications requiring speed (intakes, fast movements), some precision may be sacrificed. Understanding game requirements helps teams make appropriate tradeoffs. Sometimes multiple mechanisms (fast rough positioning, slow precise positioning) provide optimal solution.

**Design Process Best Practices:**
Effective design follows systematic process. Problem identification involves understanding game requirements, identifying scoring opportunities, and defining robot objectives clearly. Research includes studying past game solutions, analyzing successful robot designs, and understanding mechanical principles. Brainstorming generates multiple design concepts without premature judgment - quantity and diversity of ideas improve chances of finding good solutions. Concept evaluation compares options based on criteria (reliability, complexity, performance, weight, cost) - teams should evaluate objectively and document reasoning. Detailed design develops selected concept with specific dimensions, materials, and components. Prototyping builds and tests design to verify functionality - teams should prototype early and test extensively. Iteration improves design based on testing results - design is iterative process, not one-time activity.

**Reliability-First Design Philosophy:**
Reliability should be primary consideration for critical mechanisms. Simple, reliable mechanisms outperform complex, unreliable ones in competition. Teams should prioritize reliability over complexity, test extensively, design for expected conditions, and plan for failures. Reliability considerations include: using proven designs when possible, minimizing failure points, designing for easy repairs, testing under competition-like conditions, and having backup plans. Teams should ask: what happens if this fails? How quickly can we repair it? Can we prevent this failure?

**Weight Management Best Practices:**
Weight is critical constraint - robots must be under 42-pound limit. Teams should track weight continuously throughout design and build, identify heavy components that could be optimized, use lightweight materials where possible, eliminate unnecessary components, and optimize designs for weight. Weight distribution also matters - teams should balance weight for stability and performance. Teams should have weight margin (don't design to exact limit - leave buffer for additions and repairs). Weight optimization is ongoing process throughout season.

**Testing and Validation Best Practices:**
Thorough testing validates design and identifies issues before competition. Component testing verifies individual components work correctly. Subsystem testing verifies subsystems function as designed. Integration testing verifies subsystems work together. System testing verifies complete robot functions correctly. Stress testing verifies robot can handle expected loads and conditions. Reliability testing verifies robot performs consistently over multiple cycles. Teams should test systematically (components, then subsystems, then complete robot), test extensively (many cycles to verify reliability), test under realistic conditions (competition-like scenarios), and document test results. Testing should continue throughout season as design evolves.

**Documentation and Learning:**
Comprehensive documentation supports design process and competition judging. Documentation should include design sketches (concept development), CAD models (detailed design), calculations (load analysis, gear ratios), test results (validation data), and design rationale (why decisions were made). Engineering notebook should tell complete design story, showing not just what was built but how and why. Documentation helps teams remember design decisions, supports troubleshooting, and demonstrates engineering process to judges. Teams should document continuously throughout design process, not just at end. Learning from each design iteration improves future designs.
"""
            
        case "Getting Started with Programming":
            return """
**Programming Fundamentals:**
Programming is the process of writing instructions that tell your robot what to do. In FTC, programming brings your robot to life - it controls motors, servos, sensors, and responds to driver input. Understanding fundamental programming concepts is essential before building complex robot behaviors. Programming involves breaking down tasks into smaller steps, writing code to execute those steps, testing to verify code works correctly, and debugging when things don't work as expected. The FTC SDK provides libraries and tools that make programming easier, but teams still need to understand basic concepts to use them effectively.

**Blocks vs Java Programming:**
FTC offers two programming languages: Blocks (visual drag-and-drop) and Java (text-based). Blocks uses visual blocks that snap together, making it easier to learn and understand. Blocks is ideal for beginners, teams new to programming, or when rapid prototyping is needed. Java uses text-based code, providing more flexibility and power. Java is ideal for advanced teams, complex programs, or when maximum control is needed. Both languages use the same FTC SDK and can achieve the same results - the choice depends on team experience, preferences, and project requirements. Teams can start with Blocks and transition to Java as they gain experience, or start with Java if team members have programming background.

**LinearOpMode vs OpMode:**
FTC programs are organized into OpModes (operational modes). LinearOpMode executes code sequentially from top to bottom, making it easier to understand and debug. LinearOpMode is ideal for beginners, simple programs, or when sequential execution is appropriate. OpMode uses a loop-based structure with init(), loop(), and stop() methods, providing more control over execution timing. OpMode is ideal for advanced programs, when precise timing control is needed, or for complex state management. Teams should understand both types and choose based on program requirements. Most teams start with LinearOpMode and progress to OpMode as needed.

**Reading and Writing to Hardware:**
Hardware interaction is fundamental to robot programming. Reading from hardware means getting information from sensors (encoder values, IMU orientation, distance measurements). Writing to hardware means controlling actuators (setting motor power, positioning servos, activating mechanisms). The FTC SDK provides classes and methods for all hardware types. Teams must declare hardware in configuration, initialize hardware in code, read sensor values when needed, and write control values to actuators. Understanding hardware mapping, initialization, and control is essential for all robot programs. Teams should practice with simple hardware interactions before building complex programs.

**Android Studio Setup:**
Android Studio is the development environment for FTC programming. Setup involves downloading Android Studio, installing FTC SDK, configuring project settings, and connecting to robot. Teams should follow official FTC documentation for setup instructions, ensure all required components are installed, configure Android Studio properly, and test connection to robot. Common setup issues include incorrect SDK versions, missing drivers, configuration problems, and connection issues. Teams should troubleshoot systematically, check official documentation, and seek help from forums when needed. Proper setup is essential for productive programming.

**Common Programming Issues:**
Teams encounter various programming issues. Compilation errors occur when code syntax is incorrect - teams should read error messages carefully and fix syntax issues. Runtime errors occur when code executes incorrectly - teams should use debugging tools and check logic. Hardware connection issues prevent code from running - teams should verify hardware configuration and connections. Performance issues cause slow or unresponsive robots - teams should optimize code and check for bottlenecks. Teams should learn to read error messages, use debugging tools effectively, test code incrementally, and seek help when stuck. Understanding common issues helps teams resolve problems quickly.
"""
            
        case "Control Systems & Sensors":
            return """
**Control Loop Fundamentals:**
Control loops use feedback to achieve desired outputs. Open-loop control sets outputs without feedback - simple but inaccurate. Closed-loop control uses feedback to adjust outputs - more complex but accurate. PID (Proportional-Integral-Derivative) controllers are common closed-loop controllers. Proportional term responds to current error (difference between desired and actual). Integral term responds to accumulated error over time. Derivative term responds to rate of error change. PID controllers require tuning (adjusting P, I, D coefficients) for optimal performance. Teams should understand control loop concepts, learn to implement PID controllers, and practice tuning for different applications.

**Finite State Machines:**
Finite state machines organize robot behavior into discrete states. Each state represents a specific robot condition or behavior. Transitions between states occur based on conditions (sensor readings, time, user input). State machines make complex behaviors manageable by breaking them into simpler pieces. Common applications include autonomous routines (states for different phases), mechanism control (states for different positions), and game strategy (states for different game situations). Teams should identify robot states, define state transitions, implement state machine structure, and test state transitions. State machines improve code organization and make complex behaviors easier to understand and debug.

**Encoder Integration:**
Encoders provide position and velocity feedback for motors. Motor encoders are built into motors, providing counts per revolution. External encoders can be added for additional feedback. Encoder values indicate motor position (how far motor has rotated) and can be used to calculate velocity (how fast motor is rotating). Teams use encoders for precise movement (drive specific distances), position control (move mechanisms to specific positions), and velocity control (maintain specific speeds). Encoder integration involves reading encoder values, converting counts to physical units (inches, degrees), using values for control, and handling encoder resets. Teams should understand encoder resolution, direction, and calibration for accurate control.

**IMU (Inertial Measurement Unit) Usage:**
IMU provides orientation and heading information. IMU measures acceleration, angular velocity, and magnetic field to determine robot orientation. Heading (yaw angle) indicates which direction robot is facing, essential for autonomous navigation. Pitch and roll angles indicate robot tilt, useful for balancing or climbing. IMU integration involves initializing IMU, reading orientation angles, using angles for navigation, and handling IMU calibration. Teams use IMU for field-oriented control (maintain consistent orientation), autonomous navigation (know which direction robot faces), and balancing (detect robot tilt). IMU requires calibration and can drift over time - teams should understand calibration procedures and handle drift appropriately.

**Vision Sensor Integration:**
Vision sensors detect game elements and field features. Webcams capture images that can be analyzed for object detection. Color sensors detect specific colors, useful for identifying game elements. Distance sensors measure distances to objects. Vision processing involves capturing images, analyzing image data, identifying targets, and using information for control. Computer vision libraries (like OpenCV or Vuforia) provide tools for image processing. Teams use vision for autonomous navigation (detect field features), game element detection (identify scoring targets), and alignment (position robot precisely). Vision processing is computationally intensive - teams should optimize code for performance and handle processing delays appropriately.

**Sensor Fusion and Integration:**
Multiple sensors provide complementary information. Sensor fusion combines data from multiple sensors for better accuracy and reliability. Encoders provide position, IMU provides orientation, vision provides target detection - combining these enables sophisticated autonomous behaviors. Teams should understand each sensor's strengths and limitations, combine sensor data appropriately, handle sensor conflicts (when sensors disagree), and validate sensor readings. Effective sensor integration enables reliable autonomous operation and precise robot control. Teams should test sensor integration thoroughly and handle sensor failures gracefully.
"""
            
        case "Autonomous Programming":
            return """
**Autonomous Period Overview:**
The autonomous period is the first 30 seconds of each match when drivers cannot control the robot. All movement and actions must be pre-programmed. Autonomous points are often significant (20-40 points) and can determine match outcomes. Effective autonomous routines require precise programming, reliable sensors, and extensive testing. Teams should program multiple autonomous routines for different starting positions, test extensively under competition-like conditions, and refine based on results. Autonomous programming is challenging but provides significant competitive advantages.

**Path Planning Fundamentals:**
Path planning determines robot paths to reach targets. Simple paths move directly to targets - straightforward but may not be optimal. Complex paths avoid obstacles, optimize for time, or follow specific trajectories. Path planning involves identifying start and end positions, determining intermediate waypoints, calculating path segments, and generating movement commands. Teams should consider field constraints (obstacles, boundaries), optimize for time (shortest or fastest paths), and plan for error recovery (what if robot doesn't reach target?). Path planning is essential for effective autonomous navigation.

**Odometry and Localization:**
Odometry tracks robot position on field using sensor data. Dead-wheel odometry uses wheels that don't drive robot (dead wheels) to measure movement, providing accurate position tracking. Encoder odometry uses drive wheel encoders to estimate position, simpler but less accurate. IMU odometry uses orientation data to improve position estimates. Localization determines robot's position on field, essential for autonomous navigation. Teams use odometry for precise movement (know where robot is), path following (follow planned paths accurately), and error correction (adjust when off course). Odometry requires calibration and can accumulate error over time - teams should understand error sources and implement correction strategies.

**Computer Vision for Autonomous:**
Computer vision enables robots to detect and track game elements autonomously. Vision processing involves capturing images, analyzing for targets, identifying game elements, and using information for navigation or scoring. Common applications include detecting game elements (cubes, balls, rings), identifying field features (landmarks, targets), and alignment (positioning robot precisely). Vision libraries (Vuforia, OpenCV, TensorFlow) provide tools for image processing. Teams should optimize vision code for performance, handle lighting variations, and test under competition conditions. Vision processing adds complexity but enables sophisticated autonomous behaviors.

**Kinematics and Motion Control:**
Kinematics models robot motion mathematically. Forward kinematics calculates robot position from motor movements. Inverse kinematics calculates required motor movements for desired robot position. Kinematics enables precise movement control, especially for complex drivetrains (mecanum, swerve). Motion control uses kinematics and feedback to achieve desired movements accurately. Teams use kinematics for precise positioning, coordinated movement, and path following. Kinematics requires understanding robot geometry, mathematical modeling, and control algorithms. Advanced teams use kinematics for sophisticated autonomous behaviors.

**Autonomous Strategy Development:**
Effective autonomous strategies maximize points while ensuring reliability. Strategy development involves analyzing game requirements (what scores points?), identifying opportunities (what can robot do autonomously?), evaluating risks (what could go wrong?), and selecting approaches (which strategy is best?). Teams should program multiple strategies for different scenarios, test extensively, and refine based on results. Autonomous strategies should be simple enough to be reliable but sophisticated enough to score significant points. Teams should balance complexity and reliability based on capabilities and game requirements.

**Testing and Refinement:**
Thorough testing is essential for reliable autonomous operation. Testing should occur under competition-like conditions (same field, lighting, surfaces), include multiple test runs to verify consistency, test different starting positions and scenarios, and validate sensor readings and calculations. Teams should document test results, identify issues, refine code based on results, and retest after changes. Autonomous testing requires significant time investment but is essential for competition success. Teams should test continuously throughout season as game understanding and robot capabilities evolve.
"""
            
        case "Advanced Programming Techniques":
            return """
**TeleOp Optimization:**
Effective TeleOp programming maximizes driver effectiveness. Responsive controls ensure robot responds quickly to driver input without delay. Smooth movement prevents jerky motion that makes driving difficult. Reliable mechanisms ensure mechanisms work consistently when drivers activate them. Intuitive gamepad mapping makes controls easy to learn and use. Teams should optimize for driver experience - controls should feel natural, mechanisms should respond predictably, and robot should be easy to drive effectively. Driver feedback is essential - teams should work with drivers to optimize controls and improve driving experience.

**Gamepad Usage and Mapping:**
Gamepads provide driver input for robot control. Effective gamepad mapping assigns controls logically and intuitively. Common mappings: left stick for drivetrain, right stick for turning, triggers for mechanisms, buttons for discrete actions. Teams should consider driver preferences, game requirements, and mechanism needs when mapping controls. Advanced techniques include: button combinations for complex actions, toggle buttons for state changes, analog control for variable outputs, and driver-specific mappings. Teams should test gamepad mappings with drivers, refine based on feedback, and document mappings clearly. Good gamepad mapping significantly improves driver effectiveness.

**Telemetry for Debugging:**
Telemetry displays information on Driver Station screen during matches. Effective telemetry helps drivers and programmers understand robot state. Common telemetry includes: sensor readings (encoder values, IMU angles), mechanism positions (arm angles, slide extensions), game state information (match time, scores), and debug information (error messages, state information). Teams should display relevant information clearly, update telemetry frequently, and use telemetry for debugging during development. Telemetry is valuable for troubleshooting issues during matches and understanding robot behavior. Teams should use telemetry effectively but avoid cluttering display with unnecessary information.

**Code Organization and Structure:**
Well-organized code is easier to understand, maintain, and improve. Code organization involves: grouping related functionality (motors together, sensors together), using descriptive names (clear variable and method names), adding comments (explain complex logic), and modularizing code (separate concerns into methods/classes). Teams should establish coding standards, organize code logically, document complex sections, and refactor code regularly. Good code organization improves team productivity, makes debugging easier, and enables easier improvements. Teams should invest time in code organization - it pays dividends throughout season.

**Performance Optimization:**
Optimized code runs faster and more efficiently. Performance optimization involves: reducing unnecessary calculations, optimizing loops (avoid nested loops when possible), minimizing sensor reads (use bulk reads when available), and efficient algorithms (choose appropriate algorithms for tasks). Teams should profile code to identify bottlenecks, optimize critical sections, and balance optimization with code clarity. Performance optimization is important for responsive controls and efficient autonomous operation. Teams should optimize where needed but maintain code readability - premature optimization can make code harder to understand and maintain.

**Error Handling and Robustness:**
Robust code handles errors gracefully and continues operating. Error handling involves: checking for error conditions (sensor failures, hardware issues), implementing fallback behaviors (what to do when errors occur), logging errors for debugging, and preventing crashes. Teams should anticipate potential failures, implement error handling, test error scenarios, and ensure robot continues operating when possible. Robust code is essential for competition reliability - robots must handle unexpected situations without crashing. Teams should test error handling and ensure graceful degradation when failures occur.
"""
            
        case "SDK & Hardware Integration":
            return """
**FTC SDK Overview:**
The FTC SDK (Software Development Kit) provides libraries and tools for robot programming. The SDK includes: hardware classes (motors, servos, sensors), control system interfaces (gamepad, telemetry), utility classes (time, math functions), and example code. Teams use the SDK to interact with robot hardware, control mechanisms, read sensors, and respond to driver input. Understanding the SDK structure and capabilities is essential for effective programming. Teams should explore SDK documentation, study example code, and understand available classes and methods. The SDK is continuously updated - teams should stay current with latest versions and new features.

**Motor Control and Configuration:**
Motors are primary actuators for robot movement and mechanisms. Motor control involves: declaring motors in configuration, initializing motors in code, setting motor power (speed and direction), using encoders for position/velocity control, and configuring motor behavior (braking, run modes). The SDK provides DcMotor class for motor control with methods for power, position, and velocity control. Teams should understand motor modes (RUN_WITHOUT_ENCODER, RUN_USING_ENCODER, RUN_TO_POSITION), encoder usage, and power scaling. Advanced motor control includes: velocity PID control, position control, and coordinated multi-motor control. Teams should configure motors properly, use appropriate control modes, and test motor behavior thoroughly.

**Servo Control and Positioning:**
Servos provide precise angular positioning for mechanisms. Servo control involves: declaring servos in configuration, initializing servos in code, setting servo positions (0.0 to 1.0 range), and using servo controllers for multiple servos. The SDK provides Servo class for servo control with methods for position setting and reading. Teams should understand servo range (typically 0-180 degrees), position mapping (converting angles to 0-1 range), and servo controllers (CRServo for continuous rotation). Servo control is simpler than motor control but requires understanding position ranges and mapping. Teams should calibrate servos, test position accuracy, and handle servo initialization properly.

**Sensor Integration and Reading:**
Sensors provide feedback for robot control and autonomous operation. Sensor integration involves: declaring sensors in configuration, initializing sensors in code, reading sensor values, processing sensor data, and using data for control. The SDK provides classes for various sensors: encoders (position/velocity), IMU (orientation), color sensors, distance sensors, touch sensors, and vision sensors. Teams should understand sensor capabilities, read values correctly, handle sensor initialization, and process data appropriately. Sensor integration enables autonomous operation, precise control, and responsive mechanisms. Teams should test sensors thoroughly, handle sensor failures gracefully, and calibrate sensors when needed.

**Bulk Reads for Performance:**
Bulk reads improve performance by reading multiple sensors simultaneously. Instead of reading sensors individually (slow), bulk reads read all sensors in one operation (fast). Bulk reads reduce loop time, improve control responsiveness, and enable more complex programs. The SDK provides bulk read capabilities for compatible sensors. Teams should use bulk reads when reading multiple sensors, understand bulk read timing, and ensure sensor compatibility. Bulk reads are essential for high-performance programs with multiple sensors. Teams should implement bulk reads for improved performance.

**Control System Electronics:**
Understanding control system electronics helps teams program effectively. The Control Hub is the main computer running robot code. Expansion Hubs provide additional I/O ports for motors, servos, and sensors. Communication between hubs uses I2C protocol. Teams should understand hub configuration, port assignments, and communication protocols. Understanding electronics helps teams troubleshoot issues, configure hardware correctly, and optimize performance. Teams should study control system documentation and understand hardware architecture for effective programming.
"""
            
        case "Control Hub & Expansion Hub":
            return """
**Control System Overview:**
The FTC control system is based around a Robot Controller and Driver Station. The Robot Controller runs robot code and is either embedded within a Control Hub or runs on a separate Android phone. Hubs (Control Hub or Expansion Hubs) connect to motors, servos, and sensors, providing the interface between software and hardware. Communication between Robot Controller and Driver Station occurs via WiFi or WiFi Direct. REV Robotics is the sole manufacturer of legal FTC control system components.

**REV Control Hub:**
The Control Hub is an all-in-one solution combining Robot Controller and Hub functionality. It includes built-in Robot Controller (Android-based), motor ports (4 ports), servo ports (6 ports), sensor ports (I2C, analog, digital), USB ports for expansion, and WiFi connectivity. The Control Hub connects to Expansion Hubs through RS-485 or USB connections for additional I/O ports. Control Hub setup involves: firmware updates (critical - update to at least version 1.8.2), configuration via REV Hardware Client, network setup (WiFi configuration), and hardware configuration (motor/servo/sensor mapping). Teams should follow REV documentation for proper setup and configuration.

**REV Expansion Hub:**
Expansion Hubs provide additional I/O ports when Control Hub ports are insufficient. Expansion Hubs connect to Control Hub via RS-485 or USB connections. Each Expansion Hub provides: motor ports (4 ports), servo ports (6 ports), sensor ports (I2C, analog, digital), and USB ports. Multiple Expansion Hubs can be daisy-chained for even more ports. Expansion Hub setup involves: firmware updates (critical - update to at least version 1.8.2), proper USB connection with strain relief (USB Retention Mount highly recommended), RS-485 connection if using that method, and configuration via REV Hardware Client. Proper strain relief and cable management are essential for reliable operation.

**System Configuration:**
Control system configuration involves multiple steps. Hardware configuration maps physical hardware to software names (motor ports, servo ports, sensor ports). Network configuration sets up WiFi communication between Robot Controller and Driver Station. Firmware updates ensure latest features and bug fixes (critical for reliability). Configuration is done via REV Hardware Client application. Teams should document configuration, test communication reliability, and verify all hardware is properly mapped. Proper configuration is essential for robot operation - incorrect configuration prevents robot from functioning.

**Troubleshooting Common Issues:**
Common control system issues include: disconnects (robot loses communication with Driver Station), hardware not detected (motors/servos/sensors not recognized), firmware issues (outdated firmware causes problems), and connection problems (USB/RS-485 connections fail). Troubleshooting involves: checking firmware versions (update if needed), verifying connections (USB, RS-485, power), testing network connectivity (WiFi signal strength, interference), checking hardware configuration (verify port assignments), and reviewing error messages. Teams should follow REV troubleshooting guides and seek help from forums when needed. Proper troubleshooting saves significant time during competition.
"""
            
        case "Motors & Actuators":
            return """
**Motor Fundamentals:**
12-volt DC motors are primary actuators for FTC robots, powering drivetrains, intakes, lifts, and other mechanisms. Motors consist of DC motor and integrated gearbox providing speed/torque ratios. Understanding motor specifications (free speed, stall torque, gear ratios, power requirements) enables teams to select appropriate motors for applications. Motor selection depends on application requirements: drivetrains need balanced speed and torque, intakes need high speed, lifts need high torque. Teams should understand motor capabilities and limitations for effective usage.

**Motor Selection Guide:**
Motor selection involves understanding application requirements and motor specifications. Common gear ratios include: 3.7:1 (high speed, ~1600 RPM, low torque), 5.2:1 (balanced, ~1000 RPM, moderate torque), 13.7:1 (high torque, ~400 RPM, moderate speed), and 19.2:1 (very high torque, ~300 RPM, low speed). Teams should select gear ratios based on speed requirements, torque requirements, and application needs. Motor selection also considers: power requirements (ensure sufficient power available), weight constraints (motors contribute to robot weight), and reliability (some motors more reliable than others). Teams should research motor options, understand specifications, and select based on application requirements.

**Gearbox Internals:**
Gearboxes reduce motor speed and increase torque through gear reduction. Understanding gearbox internals helps teams understand motor behavior, diagnose issues, and select appropriate motors. Gearboxes consist of: input gear (attached to motor shaft), intermediate gears (transfer power), output gear (attached to output shaft), and bearings (support rotating components). Gear ratios determine speed/torque relationship - higher ratios provide more torque but less speed. Gearbox efficiency affects power transfer - some power lost to friction. Teams should understand gearbox operation for effective motor usage and troubleshooting.

**Motor Wiring and Mounting:**
Proper motor wiring and mounting are essential for reliable operation. Motor wiring involves: using appropriate wire gauge (18 AWG for motors), proper connector crimping (secure connections), correct polarity (motors reverse direction if polarity reversed), and strain relief (prevent wire damage). Motor mounting involves: secure fastening (motors experience significant forces), proper alignment (misalignment causes binding and wear), and accessibility (can access for maintenance). Teams should follow wiring best practices, use quality connectors, and ensure secure mounting. Poor wiring or mounting causes failures and safety hazards.

**Motor Power and Control:**
Motor power requirements depend on application. Motors draw current based on load - higher loads require more current. Teams must ensure power system can supply required current. Motor control involves: setting power levels (0.0 to 1.0 range), controlling direction (forward/reverse), using encoders for feedback, and implementing control algorithms (PID for precise control). Teams should understand power requirements, implement proper control, and monitor motor performance. Overloading motors causes damage and failures. Proper power management and control ensure reliable motor operation.

**Servo Control and Applications:**
Servos provide precise angular positioning for mechanisms requiring accuracy rather than high power. Servos use PWM signals for control and typically have limited rotation range (180° is common). Servos are ideal for: claws and grabbers (precise gripping), arms (positioning end effectors), and mechanisms requiring precise positioning. Servo selection depends on: torque requirements (can servo handle load?), speed needs (how fast must servo move?), and durability (metal gears more durable). Servos require proper mounting and support - servos act as levers, so loads are amplified. Teams should understand servo capabilities and limitations for effective usage.
"""
            
        case "Sensors & Feedback Systems":
            return """
**Sensor Fundamentals:**
Sensors provide feedback for robot control and autonomous operation. Understanding sensor types, capabilities, and proper usage enables teams to build sophisticated autonomous behaviors and precise control systems. Sensors convert physical quantities (position, orientation, distance, color) into electrical signals that software can process. Effective sensor integration requires: proper wiring and configuration, understanding sensor specifications, data processing and interpretation, and calibration when needed. Teams should select sensors based on application requirements and available resources.

**Encoder Integration:**
Encoders provide position and velocity feedback for motors. Motor encoders are built into motors, providing counts per revolution. External encoders can be added for additional feedback. Encoder values indicate motor position (how far motor has rotated) and can be used to calculate velocity (how fast motor is rotating). Teams use encoders for: precise movement (drive specific distances), position control (move mechanisms to specific positions), and velocity control (maintain specific speeds). Encoder integration involves: reading encoder values, converting counts to physical units (inches, degrees), using values for control, and handling encoder resets. Teams should understand encoder resolution, direction, and calibration for accurate control.

**IMU (Inertial Measurement Unit) Usage:**
IMU provides orientation and heading information essential for autonomous navigation. IMU measures acceleration, angular velocity, and magnetic field to determine robot orientation. Heading (yaw angle) indicates which direction robot is facing. Pitch and roll angles indicate robot tilt, useful for balancing or climbing. IMU integration involves: initializing IMU, reading orientation angles, using angles for navigation, and handling IMU calibration. Teams use IMU for: field-oriented control (maintain consistent orientation), autonomous navigation (know which direction robot faces), and balancing (detect robot tilt). IMU requires calibration and can drift over time - teams should understand calibration procedures and handle drift appropriately.

**Vision Sensors:**
Vision sensors detect game elements and field features. Webcams capture images that can be analyzed for object detection. Color sensors detect specific colors, useful for identifying game elements. Distance sensors measure distances to objects. Vision processing involves: capturing images, analyzing image data, identifying targets, and using information for control. Computer vision libraries (like OpenCV or Vuforia) provide tools for image processing. Teams use vision for: autonomous navigation (detect field features), game element detection (identify scoring targets), and alignment (position robot precisely). Vision processing is computationally intensive - teams should optimize code for performance and handle processing delays appropriately.

**Other Sensor Types:**
Additional sensors provide various feedback capabilities. Touch sensors detect physical contact, useful for limit switches and collision detection. Distance sensors (ultrasonic, time-of-flight) measure distances to objects. Color sensors detect colors, useful for identifying game elements. Teams should understand sensor capabilities, select appropriate sensors for applications, and integrate sensors properly. Sensor selection depends on application requirements, available resources, and integration complexity. Teams should research sensor options and understand specifications for effective usage.

**Sensor Fusion:**
Multiple sensors provide complementary information. Sensor fusion combines data from multiple sensors for better accuracy and reliability. Encoders provide position, IMU provides orientation, vision provides target detection - combining these enables sophisticated autonomous behaviors. Teams should understand each sensor's strengths and limitations, combine sensor data appropriately, handle sensor conflicts (when sensors disagree), and validate sensor readings. Effective sensor integration enables reliable autonomous operation and precise robot control. Teams should test sensor integration thoroughly and handle sensor failures gracefully.
"""
            
        case "Wiring & Electrical Safety":
            return """
**Wiring Fundamentals:**
Proper wiring is critical for reliable robot operation. Wiring practices include: using appropriate wire gauge (18 AWG for motors, 22 AWG for servos), proper connector selection and crimping, cable management and strain relief, and electrical safety compliance. Poor wiring causes failures, safety hazards, and competition disqualification. Teams should follow wiring best practices, use quality components, and test wiring thoroughly. Good wiring is essential for competition reliability.

**Wire Gauge and Selection:**
Wire gauge refers to wire diameter - larger gauge numbers indicate smaller wire diameter. Appropriate wire gauge depends on current requirements. Motor wires typically use 18 AWG (higher current capacity). Servo wires typically use 22 AWG (lower current requirements). Wire selection involves: understanding current requirements, selecting appropriate gauge, ensuring sufficient capacity with safety margin, and considering wire length (longer wires need larger gauge). Teams should use appropriate wire gauge for applications - undersized wires overheat and cause failures, oversized wires waste weight and space.

**Connector Selection and Crimping:**
Proper connectors ensure reliable electrical connections. Connector selection depends on: application (motors, servos, sensors), current requirements, and reliability needs. Common connectors include: Anderson Powerpole (motor connections), JST (servo connections), and various sensor connectors. Proper crimping is essential - poor crimps cause failures. Crimping involves: selecting correct connector size, stripping wire properly, crimping securely, and testing connections. Teams should use quality crimping tools, practice crimping technique, and test connections thoroughly. Poor connections cause intermittent failures that are difficult to diagnose.

**Cable Management:**
Cable management improves reliability and maintainability. Cable routing should: minimize length (reduce weight, improve reliability), avoid interference (keep signal and power wires separated), ensure accessibility (can access for repairs), and protect cables (avoid pinch points, sharp edges). Teams should use cable management solutions (cable ties, cable management channels, wire loom), label cables clearly (function, destination), and organize cables logically. Poor cable management causes failures (wires break, connections come loose, interference issues) and makes repairs difficult. Good cable management is sign of professional robot design.

**Electrical Safety:**
Electrical safety is critical for competition compliance and team safety. Safety requirements include: proper battery handling (secure mounting, protection from damage), secure connections (prevent shorts and disconnects), protection from exposed wires (insulation, covers), and compliance with FTC safety rules. Teams must pass electrical safety inspection before competing. Safety violations cause disqualification and pose hazards. Teams should: review safety requirements, implement safety measures, test safety compliance, and prepare for inspection. Electrical safety is non-negotiable - teams must comply to compete.

**Battery Management:**
Battery management ensures reliable power supply. Battery considerations include: capacity (how long robot can run), voltage (12V nominal), charging (proper charging procedures), and safety (secure mounting, protection). Teams should: monitor battery voltage, charge batteries properly, secure batteries in robot, and have backup batteries for competition. Battery failures cause robot shutdowns during matches. Proper battery management ensures reliable operation throughout competition day. Teams should understand battery specifications and follow proper procedures.
"""
            
        case "Driver Station & Communication":
            return """
**Driver Station Overview:**
The Driver Station provides interface between drivers and robot. Options include REV Driver Hub (purpose-built device) or Android phones. Driver Station configuration involves: hardware configuration (gamepad setup, network configuration), software setup (Driver Station app installation and configuration), and network setup (WiFi configuration for robot communication). Proper Driver Station setup ensures reliable communication, responsive controls, and effective driver experience. Teams should understand Driver Station options, configure properly, and test communication reliability.

**REV Driver Hub:**
REV Driver Hub is purpose-built device for FTC with several advantages. Advantages include: full-sized USB ports (no flimsy OTG cables), USB-C charging with fast charging, larger screen than many phones, and robust case. Disadvantages include: higher cost ($250 vs. used phones), reported power issues (improperly sized batteries), battery drain in sleep mode, and occasional WiFi driver crashes. Teams should follow REV troubleshooting guides if experiencing issues. Driver Hub provides better experience but at higher cost - teams should evaluate based on budget and needs.

**Android Phone Driver Station:**
Android phones are legal and cost-effective Driver Station option. Advantages include: low cost (can purchase secondhand), generally reliable out of box. Disadvantages include: require OTG cables (flimsy connections), need protection cases, and 2.4 GHz phones may experience lag at competitions (crowded WiFi). Teams should prefer 5 GHz phones to reduce ping issues. OTG cable quality is critical - poor cables cause disconnects. Teams should purchase quality OTG cables and USB hubs. Android phones work well but require careful setup and quality accessories.

**Gamepad Configuration:**
Gamepads provide driver input for robot control. Legal controllers include: Xbox 360 Controller for Windows, Logitech F310 Controller, ETPark Wired Controller for PS4, and Sony DualShock 4 (wired connection required). Controller selection depends on: driver preferences, availability, and cost. PS4 controllers generally preferred for better triggers, bumpers, and trackpad support. Teams should ensure drivers have experience with chosen controllers. Gamepad configuration involves: connecting gamepads to Driver Station, configuring in Driver Station app, and testing responsiveness. Proper gamepad setup ensures effective driver control.

**Network Configuration:**
Network configuration sets up communication between Robot Controller and Driver Station. Configuration involves: WiFi setup (network selection, password entry), WiFi Direct setup (direct connection option), and network testing (verify reliable communication). Teams should: test network reliability, minimize interference, use 5 GHz when possible, and have backup network options. Network issues cause disconnects and lag. Proper network configuration ensures reliable communication during matches. Teams should test network setup thoroughly before competition.

**Troubleshooting Communication:**
Communication issues cause robot disconnects and lag. Common issues include: WiFi interference (crowded networks at competitions), poor signal strength (distance, obstacles), OTG cable problems (poor quality cables), and network configuration errors. Troubleshooting involves: checking signal strength, testing network connectivity, verifying cable connections, reviewing network configuration, and testing under competition-like conditions. Teams should identify and resolve communication issues before competition. Reliable communication is essential for effective robot control.
"""
            
        case "Starting & Organizing a Team":
            return """
**Team Formation Fundamentals:**
Starting an FTC team requires careful planning and organization. Teams must recruit members, find mentors, select appropriate team structure, and secure funding. The process involves multiple steps: identifying interested students, reaching out to potential mentors, choosing team structure (school, home, or community team), and developing funding proposals. Teams should start early - registration opens in May for following season. Successful team formation requires persistence, clear communication, and demonstrating value to potential supporters.

**Recruiting Team Members:**
Recruiting members is essential for team sustainability. Effective recruitment involves: creating catchy flyers and promotional materials, holding interest meetings (bring food to attract attendance), discussing FTC benefits for students and parents, being inclusive (people may discover passions through FIRST), and collecting contact information for follow-up. Teams should recruit from grades 7+ to ensure constant flow of members as older students graduate. Recruitment should emphasize educational benefits, STEM learning, teamwork, and competitive opportunities. Teams should make recruitment ongoing process, not just one-time event.

**Finding Mentors:**
Mentors are critically important - good mentors can make difference between great season and difficult one. Teams need multiple mentors (not just one) to cover wide variety of engineering and business problems. To find mentors: reach out to STEM teachers in area, contact local businesses for employee volunteers, leverage new recruit connections, and emphasize in-person mentorship (more effective than remote). Teams must have at least two mentors over 18, and all mentors must pass FIRST Youth Protection Screening (free, annual background check). Mentors fall into roles: technical (robot and engineering advice), soft skills (leadership, fundraising, marketing, logistics), or both. Teams should not be afraid to involve mentors who aren't highly "technical" - they're sometimes best ones.

**Team Structure Selection:**
Teams must choose structure that fits their situation. School Teams are school-affiliated with school funding - advantages include easier sustainability and potential consistent funding, but disadvantages include less practice freedom, part sourcing restrictions, competing for funding yearly, and limited/no summer practice. Home Teams operate from private residences - advantages include schedule freedom and part sourcing flexibility, but disadvantages include funding challenges and sustainability concerns. Community Teams operate from community centers or organizations - advantages include community support and flexibility, but disadvantages include finding suitable space and funding. Teams should carefully consider which structure fits their situation and resources.

**Securing Funding:**
Funding is essential for team operation. Typical FTC season budget includes: FIRST Registration ($295), region/competition costs ($250-$800+), game set ($450/season), competition field ($659, replacement every 2-3 years), Control and Communication set ($265), Electronics set ($282), Expansion Hub ($250), goBILDA Starter Kit ($600), and sensors/servos ($500+). Total startup costs approximately $4,000, with $2,500/year ongoing. Teams can reduce costs through: fundraising and sponsorship, cost-saving measures (inventory management, used parts, grants, 3D printing, cost-effective manufacturing), and minimum fundraising requirements (preferred over team fees which can exclude less fortunate members). Teams should not underpitch budget needs - seize opportunity to pitch larger budget when available.
"""
            
        case "Outreach & Community Engagement":
            return """
**Outreach Fundamentals:**
Outreach is core to FIRST values and essential for awards success. Outreach involves engaging with local communities, inspiring younger students, building industry connections, and demonstrating team impact. Effective outreach demonstrates team values, builds community support, provides learning opportunities, and strengthens award presentations. Teams should plan outreach activities, document impact, and integrate outreach into team culture. Outreach is not just requirement - it's opportunity to make positive impact and build lasting relationships.

**Educational Outreach:**
Educational outreach inspires younger students and builds STEM pipeline. Activities include: hosting workshops for elementary/middle school students, demonstrating robots at schools and events, mentoring FLL teams, creating educational content (videos, tutorials, presentations), and participating in STEM fairs and events. Educational outreach benefits: inspires next generation, teaches team members (teaching reinforces learning), demonstrates community impact, and strengthens award presentations. Teams should plan educational activities, prepare age-appropriate content, and document impact with photos and testimonials.

**Community Service:**
Community service demonstrates team values and makes positive impact. Activities include: volunteering at community events, supporting local charities, organizing community STEM events, providing technical assistance to community organizations, and participating in community improvement projects. Community service benefits: makes positive impact, builds community relationships, demonstrates team values, and provides learning opportunities. Teams should identify community needs, plan service activities, and document impact. Community service should be genuine and meaningful, not just for awards.

**Industry Connections:**
Building industry connections provides resources, mentorship, and opportunities. Activities include: reaching out to local STEM businesses, requesting sponsorships and donations, seeking technical mentorship, organizing industry tours, and building partnerships with companies. Industry connections provide: funding and resources, technical expertise, mentorship opportunities, and career connections for team members. Teams should research local companies, prepare professional pitches, maintain relationships, and express gratitude. Industry connections are long-term investments that benefit teams throughout season and beyond.

**Fundraising Strategies:**
Fundraising is essential for team sustainability. Strategies include: corporate sponsorships (pitch value proposition to businesses), individual donations (community members, alumni, parents), grant applications (FIRST grants, local foundations, STEM grants), fundraising events (car washes, bake sales, robot demonstrations), and online fundraising (crowdfunding platforms). Effective fundraising requires: clear value proposition (what benefits do sponsors receive?), professional presentation, relationship building, and gratitude expression. Teams should diversify funding sources, plan fundraising activities, and document impact for sponsors. Fundraising is ongoing process, not one-time activity.

**Documenting Outreach Impact:**
Documentation is essential for awards and demonstrating impact. Teams should document: activities (what was done?), participants (who was involved?), impact (what was achieved?), testimonials (what did participants say?), and media (photos, videos, articles). Documentation should be comprehensive, organized, and accessible. Teams should create outreach portfolio, maintain outreach log, collect testimonials, and organize media. Good documentation strengthens award presentations and demonstrates team commitment to FIRST values.
"""
            
        case "Competition Strategy":
            return """
**Strategy Development Fundamentals:**
Competition strategy involves analyzing game requirements, developing robot capabilities, planning match strategies, scouting opponents, and selecting alliance partners. Effective strategy requires understanding scoring systems, identifying high-value actions, developing multiple strategies for different scenarios, scouting data collection and analysis, and alliance selection planning. Strategy development is ongoing throughout season - teams should analyze game continuously, adapt strategies based on competition results, and prepare for various scenarios. Good strategy maximizes scoring potential and competitive success.

**Game Analysis:**
Game analysis is foundation of effective strategy. Analysis involves: understanding scoring systems (point values, bonus conditions, penalties), identifying high-value actions (what scores most points?), analyzing field layout (obstacles, scoring locations, strategic positions), understanding game flow (autonomous, TeleOp, endgame), and identifying strategic opportunities (what can provide competitive advantage?). Teams should analyze game thoroughly, calculate maximum possible scores, identify strategic opportunities, and develop multiple strategies. Game analysis should be continuous - teams should refine understanding as season progresses.

**Robot Capability Development:**
Robot capabilities determine strategic options. Teams should develop capabilities that: maximize scoring potential, provide strategic flexibility, enable multiple strategies, and adapt to different scenarios. Capability development involves: identifying required capabilities (what must robot do?), prioritizing capabilities (what's most important?), developing capabilities systematically, and testing capabilities thoroughly. Teams should balance capability development with reliability - capabilities that don't work are useless. Teams should develop core capabilities first, then add advanced capabilities as season progresses.

**Match Strategy Planning:**
Match strategy involves planning how to maximize points in each match. Strategy planning includes: autonomous strategy (what to do in 30 seconds?), TeleOp strategy (how to score points efficiently?), endgame strategy (how to maximize endgame points?), defensive strategy (when and how to play defense?), and alliance coordination (how to work with partner?). Teams should develop multiple strategies for different scenarios, practice strategies, and adapt based on match conditions. Strategy should be flexible - teams must adapt to unexpected situations during matches.

**Scouting Techniques:**
Scouting provides data for strategic decisions. Scouting involves: collecting data on opponents (capabilities, performance, reliability), analyzing scouting data (identifying strengths, weaknesses, patterns), using data for alliance selection (which teams make good partners?), and planning match strategies (how to counter opponents?). Effective scouting requires: systematic data collection, organized data analysis, and strategic application of insights. Teams should scout consistently, analyze data thoroughly, and use insights for strategic decisions. Good scouting provides competitive advantage.

**Alliance Selection Strategy:**
Alliance selection determines playoff success. Selection strategy involves: evaluating potential partners (capabilities, compatibility, reliability), planning selection order (who to pick when?), negotiating with potential partners (discussing strategies, expectations), and making informed decisions. Teams should research potential partners, evaluate compatibility, plan selection strategy, and make decisions based on data and analysis. Alliance selection is strategic decision that significantly affects playoff success. Teams should prepare for alliance selection throughout qualification matches.
"""
            
        case "Awards & Judging":
            return """
**Awards Overview:**
Awards recognize teams for engineering excellence, community impact, and team values. Awards are core part of FIRST Tech Challenge - they recognize teams at end of every competition (except league meets) and determine many teams that advance. There are 7 main awards for FTC teams (excluding awards that cannot advance teams). For winning every award, Engineering Portfolio is key reference and quintessential - teams must focus on Engineering Portfolio. Awards have level of subjectivity - there's no way to 100% control how team does, but proper preparation maximizes chances.

**Award Categories:**
Main FTC awards include: Inspire Award (highest honor, recognizes overall excellence), Think Award (recognizes engineering process and documentation), Connect Award (recognizes community engagement and outreach), Control Award (recognizes programming excellence), Design Award (recognizes mechanical design excellence), and Motivate Award (recognizes team spirit and values). Each award has specific criteria teams must meet. Teams should understand award criteria, prepare for multiple awards, and focus on Engineering Portfolio which supports all awards. Award criteria vary slightly by region - teams should contact judges about specifics.

**Engineering Portfolio:**
Engineering Portfolio is essential for all awards. Portfolio documents: design process (how team designed robot), engineering decisions (why decisions were made), outreach activities (community impact), team values (FIRST values demonstration), and team growth (learning and development). Portfolio should tell complete story of team's season, showing not just what was built but how and why. Teams should document continuously throughout season, not just at end. Portfolio should be comprehensive, well-organized, and clearly demonstrate team's excellence. Strong portfolio is foundation of award success.

**Judging Process:**
Judging process involves multiple components. Most awards include: 5-minute presentation at beginning of day (teams present to judges), Q&A time (judges ask questions), and possibly pit judging later (judges visit pit for additional questions). Teams should prepare: clear presentation (organized, engaging, comprehensive), anticipate questions (prepare answers for common questions), and demonstrate knowledge (team members should understand their work). Teams should practice presentations, prepare for questions, and ensure all team members can speak knowledgeably. Judging is opportunity to demonstrate team's excellence - teams should prepare thoroughly.

**Presentation Preparation:**
Effective presentations are essential for award success. Presentation preparation involves: organizing content (clear structure, logical flow), creating visual aids (slides, posters, demonstrations), practicing delivery (smooth, confident, engaging), preparing for questions (anticipate and practice answers), and ensuring team participation (all members should contribute). Teams should practice presentations multiple times, time presentations carefully, and ensure smooth delivery. Presentations should demonstrate team's excellence clearly and engagingly. Good presentations significantly improve award chances.

**Award Strategy:**
Teams should develop award strategy. Strategy involves: identifying target awards (which awards align with team strengths?), preparing comprehensively (strong portfolio, good presentations), demonstrating FIRST values (Gracious Professionalism, Coopertition), and maintaining consistency (excellence throughout season). Teams should not focus on single award - prepare for multiple awards to maximize chances. Award success requires: strong engineering, documented process, community impact, and demonstrated values. Teams should integrate award preparation into regular team activities, not treat as separate task.
"""
            
        case "Effective Communication":
            return """
**Communication Fundamentals:**
Effective communication is essential for team success. Communication involves: asking effective questions (research first, be specific, understand solutions), sharing knowledge within team, documenting decisions and processes, and communicating with mentors and community. Teams should establish communication systems (meetings, documentation, online platforms), practice clear communication, and develop questioning skills. Good communication improves team efficiency, enables learning, and strengthens relationships with mentors and community.

**Asking Effective Questions:**
Asking effective questions is crucial skill for learning and problem-solving. Process involves: research first (check documentation, Google, YouTube, forums, past examples before asking), be specific (break down problem, provide context, share progress, include media), and understand solution (understand why problem was solved, figure out root cause, ask for problem-solving process outline, find knowledge gaps). Teams should develop questioning skills - ability to ask good questions accelerates learning and problem-solving. When solving problems independently after posting question, teams should post response describing solution to help others.

**Team Communication Systems:**
Teams need effective communication systems. Systems include: regular meetings (1-2 mandatory meetings per week recommended), documentation (decisions, processes, knowledge), online platforms (team chat, shared documents, project management), and communication protocols (who communicates what, when, how?). Teams should establish clear communication systems, ensure all members have access, and maintain consistent communication. Good communication systems improve team efficiency and ensure everyone stays informed.

**Knowledge Sharing:**
Knowledge sharing improves team capabilities. Sharing involves: documenting knowledge (create team knowledge base), cross-training members (members learn skills outside expertise), teaching new members (dedicated onboarding program), and sharing resources (compiled resources, techniques, materials). Teams should create knowledge base, encourage cross-training, develop training programs, and share resources. Knowledge sharing ensures team knowledge is preserved and accessible, even as members graduate. Teams should make knowledge sharing part of team culture.

**Mentor Communication:**
Effective mentor communication strengthens relationships. Communication involves: regular updates (keep mentors informed of progress), asking for help (specific questions, prepared with context), expressing gratitude (thank mentors for time and help), and respecting mentor time (be prepared, be concise, be respectful). Teams should communicate regularly with mentors, prepare for mentor interactions, and express appreciation. Good mentor relationships provide valuable guidance and support throughout season.

**Documentation Best Practices:**
Documentation supports communication and learning. Best practices include: document continuously (throughout season, not just at end), be comprehensive (include decisions, processes, results), be organized (clear structure, easy to find information), and be accessible (all team members can access). Teams should document: design decisions, meeting notes, test results, outreach activities, and lessons learned. Good documentation supports learning, troubleshooting, and award preparation. Documentation should be part of regular team activities.
"""
            
        case "Game Manual & Rules":
            return """
**Game Manual Structure:**
The Game Manual is typically 100-150 pages and divided into two main parts. Part 1 (Game Rules) covers the game challenge, field setup, game elements, match procedures, scoring systems, and gameplay rules. Part 2 (Robot Rules) covers robot construction rules, size and weight constraints, part legality, inspection requirements, and technical specifications. The manual also includes appendices with field construction details, inspection checklists, and reference materials. Teams should read the entire manual multiple times, with special attention to sections relevant to their robot design and strategy.

**Part 1: Game Rules Deep Dive:**
Game Rules define the challenge, field layout, and gameplay. The field setup section provides detailed dimensions, element placement, and construction requirements. Field elements are typically constructed from official field kits and must be placed precisely according to specifications. The game challenge section describes the objectives, which usually involve manipulating game elements (cubes, balls, rings, etc.) to score points. Match procedures cover the 2-minute 30-second match structure: 30-second autonomous period (no driver control), 2-minute TeleOp period (driver control allowed), and endgame period (final 30 seconds with special rules). Scoring systems detail point values for different actions, bonus conditions, and penalty deductions. Teams must understand not just what scores points, but the exact conditions required for scoring.

**Part 2: Robot Rules Technical Specifications:**
Robot Rules define what teams can and cannot build. The starting size constraint is 18" x 18" x 18" (45.7 cm x 45.7 cm x 45.7 cm) - robots must fit within this cube at match start. After the match begins, robots can expand beyond these dimensions. Weight limits are typically 42 pounds (19.05 kg) maximum. Part legality rules specify which parts can be used - only parts from authorized suppliers (REV, TETRIX, AndyMark, etc.) that meet FTC specifications are legal. Custom parts are generally not allowed except for specific exceptions (3D printed parts for non-functional elements, custom circuit boards with restrictions). Construction rules cover fastening methods, material restrictions, and structural requirements. Teams must carefully review part legality before purchasing or using components.

**Rule Updates and Clarifications:**
Rules can be updated throughout the season via the Game Q&A system. Updates are posted on the FTC Forum and official website. Teams must check for updates regularly - missing an update can result in rule violations or missed opportunities. Updates may clarify ambiguous rules, fix errors in the manual, or modify rules based on competition feedback. Teams should subscribe to update notifications, check the forum weekly, and review all updates before each competition. When in doubt about a rule interpretation, teams should ask on the forum or contact FIRST directly. Rule updates are authoritative and override manual text.

**Inspection Requirements:**
All robots must pass inspection before competing. Inspection checks robot size (must fit in 18" cube), weight (must be under limit), part legality (only legal parts used), construction (proper fastening, no sharp edges), safety (battery secure, wires protected), and compliance with specific game rules. Teams should prepare for inspection by reviewing the inspection checklist, testing their robot fits size constraints, verifying all parts are legal, and ensuring safety requirements are met. Failed inspections delay competition participation and can cause teams to miss matches. Teams should arrive early to allow time for inspection and potential fixes. Inspection preparation is essential for competition success.
"""
            
        case "Competition Day Preparation":
            return """
**Pre-Competition Checklist:**
Thorough preparation ensures teams can compete effectively. Pre-competition checklist includes: robot inspection preparation (verify size, weight, part legality, safety compliance), battery charging (fully charge all batteries, bring backups), controller pairing (test gamepads, verify connections), autonomous testing (test all autonomous routines, verify sensors), mechanism testing (test all mechanisms, verify reliability), spare parts inventory (bring critical spares, tools, fasteners), documentation (bring game manual, rule summaries, inspection checklist), and team coordination (confirm attendance, assign roles, plan schedule). Teams should complete checklist systematically and test everything before competition.

**Packing Guide:**
Packing thoroughly ensures teams have everything needed. Essential items include: robot and components (robot, batteries, controllers, spare parts), tools (basic tool set, specialty tools, measuring tools), documentation (game manual, rule summaries, inspection checklist, engineering notebook), supplies (fasteners, wire, connectors, tape, labels), personal items (water, snacks, comfortable clothing), and backup items (backup batteries, backup controllers, backup parts). Teams should create packing list, check items off as packed, and organize items for easy access. Good packing prevents problems during competition. Teams should pack day before competition to avoid rushing.

**Practice Schedule:**
Pre-competition practice prepares teams for competition. Practice schedule should include: robot testing (test all mechanisms, verify reliability), driver practice (practice driving, test controls, practice strategies), autonomous practice (test autonomous routines, refine timing, practice different scenarios), scouting practice (practice scouting techniques, test scouting tools), and match simulation (simulate competition matches, practice pit procedures, practice communication). Teams should practice systematically, test under competition-like conditions, and refine based on practice results. Practice builds confidence and improves performance. Teams should schedule practice time before competition.

**Competition Day Timeline:**
Understanding competition day timeline helps teams prepare. Typical timeline includes: arrival and check-in (arrive early, check in, receive materials), pit setup (set up workspace, organize tools and parts, display robot), robot inspection (submit robot for inspection, address any issues, receive inspection sticker), driver meeting (attend required meeting, understand procedures, ask questions), practice matches (if available, test robot, practice driving), qualification matches (compete in scheduled matches, scout opponents, analyze results), alliance selection (if qualified, participate in selection process), elimination matches (if selected, compete in playoffs), and awards ceremony (attend ceremony, celebrate achievements). Teams should understand timeline, plan accordingly, and be flexible for schedule changes.

**Pit Setup and Organization:**
Organized pit improves efficiency and professionalism. Pit setup involves: workspace organization (designated work area, tool organization, part storage), robot display (display robot attractively, show mechanisms, demonstrate capabilities), documentation display (show engineering notebook, portfolio, awards), team branding (display team logo, colors, information), and safety compliance (follow pit safety rules, secure tools, protect robot). Teams should set up pit early, maintain organization throughout day, and clean up properly. Good pit setup creates positive impression and improves efficiency. Pit organization reflects team professionalism.
"""
            
        case "Custom Manufacturing":
            return """
**Manufacturing Fundamentals:**
Custom manufacturing enables teams to create parts not available in standard kits. Manufacturing techniques include: 3D printing (rapid prototyping, custom parts, complex geometries), machining (precise metal parts, high strength), laser cutting (flat parts, precise cuts, various materials), and other methods. Teams should understand manufacturing capabilities, select appropriate techniques for applications, and ensure parts meet FTC legality requirements. Custom manufacturing provides design flexibility but requires understanding techniques, materials, and part legality. Teams should start with simple projects and build manufacturing capabilities gradually.

**3D Printing:**
3D printing is most accessible custom manufacturing method for FTC teams. 3D printing uses additive manufacturing to create parts layer by layer from plastic filament. Advantages include: rapid prototyping (quick iteration, test designs fast), custom geometries (complex shapes, integrated features), low cost (affordable printers, inexpensive materials), and ease of use (relatively simple process). Disadvantages include: lower strength (compared to metal), material limitations (mostly plastics), and print time (can be slow for large parts). Common filaments include: PLA (easy to print, good for prototypes), ABS (stronger, more durable), PETG (strong, flexible, chemical resistant), and TPU (flexible, rubber-like). Teams should understand 3D printing design principles (overhangs, supports, infill, layer height) for effective printing.

**Machining:**
Machining provides precise, strong metal parts. Machining uses subtractive manufacturing (removing material) to create parts from metal stock. Advantages include: high strength (metal parts are strong), precision (very accurate dimensions), durability (metal parts last), and professional finish. Disadvantages include: requires equipment (mills, lathes, tooling), requires skills (machining expertise needed), time consuming (slower than 3D printing), and cost (equipment and materials expensive). Teams can use: school machine shops, maker spaces, local machine shops, or online services (SendCutSend, Fabworks). Teams should understand machining capabilities, design for manufacturability, and ensure parts meet legality requirements.

**Laser Cutting:**
Laser cutting provides precise flat parts from various materials. Laser cutting uses focused laser beam to cut or engrave materials. Advantages include: precision (very accurate cuts), speed (fast cutting), versatility (various materials), and clean edges (smooth cuts). Disadvantages include: flat parts only (limited to 2D shapes), material limitations (some materials can't be cut), and requires access (laser cutter needed). Common materials include: wood, acrylic, cardboard, fabric, and some metals (with appropriate laser). Teams can use: school laser cutters, maker spaces, or online services. Teams should understand laser cutting design principles (kerf, material thickness, cut settings) for effective cutting.

**Materials Selection:**
Material selection affects part performance and legality. Teams should understand: material properties (strength, weight, durability), FTC legality (materials must be legal), manufacturing compatibility (materials suitable for chosen manufacturing method), and cost (materials vary in cost). Common materials include: aluminum (strong, lightweight, machinable), plastics (various types, 3D printable, laser cuttable), wood (lightweight, laser cuttable, lower strength), and composites (high performance, expensive, complex). Teams should select materials based on application requirements, manufacturing capabilities, and legality. Material selection significantly affects part performance and robot weight.
"""
            
        case "Hardware Components & Parts":
            return """
**Kit Systems Overview:**
FTC uses multiple kit systems for robot construction. Understanding kit capabilities enables effective part selection. Main kit systems include: goBILDA (modular building system, extensive part library, good documentation), REV Robotics (control system and parts, high quality, good support), TETRIX (building system components, established system, good compatibility), and others. Each system has strengths and weaknesses - teams should understand capabilities, part compatibility, and integration options. Teams often use multiple systems together, requiring understanding of compatibility and integration. Kit selection affects robot design options, part availability, and build complexity.

**goBILDA System:**
goBILDA provides comprehensive modular building system. System includes: structural components (channels, brackets, plates), motion components (wheels, gears, sprockets), hardware (fasteners, bearings, shafts), and accessories (bumpers, covers, mounts). Advantages include: extensive part library (many options), good documentation (clear instructions, CAD files), modularity (easy assembly, flexible design), and active community (support, examples). Teams should understand goBILDA part numbering, compatibility, and integration with other systems. goBILDA is popular choice for many teams due to comprehensive system and good support.

**REV Robotics Components:**
REV provides control system and building components. Components include: Control Hub and Expansion Hub (control system), motors and servos (actuators), sensors (various types), structural components (channels, brackets), and accessories. Advantages include: high quality (well-made components), good support (documentation, community), integration (components work together), and reliability (proven performance). Teams should understand REV part specifications, compatibility, and integration. REV components are essential for control system and provide good building options.

**TETRIX System:**
TETRIX provides established building system. System includes: structural components (channels, angles, plates), motion components (wheels, gears, pulleys), hardware (fasteners, connectors), and accessories. Advantages include: established system (long history, proven), good compatibility (works with other systems), and availability (widely available). Teams should understand TETRIX part specifications and compatibility. TETRIX provides solid foundation for robot construction.

**Fastener Guide:**
Fasteners are essential for robot construction. Understanding fasteners enables proper assembly. Common fasteners include: screws (various types, sizes, materials), bolts (for high-strength connections), nuts (for threaded connections), washers (for load distribution), and specialty fasteners (rivets, clips, etc.). Teams should understand: fastener types and applications, proper sizing, torque requirements, and thread locking when needed. Proper fastening ensures reliable connections. Teams should use appropriate fasteners for applications and follow best practices. Poor fastening causes failures.

**Tools List:**
Proper tools are essential for robot construction and maintenance. Essential tools include: hand tools (screwdrivers, wrenches, pliers, cutters), measuring tools (rulers, calipers, levels), power tools (drills, drivers, saws), specialty tools (crimpers, soldering iron, multimeter), and safety equipment (safety glasses, gloves). Teams should maintain tool inventory, organize tools for easy access, and ensure tools are in good condition. Good tools improve build quality and efficiency. Teams should invest in quality tools and maintain them properly.
"""
            
        case "Troubleshooting & Maintenance":
            return """
**Troubleshooting Fundamentals:**
Effective troubleshooting is essential for maintaining robot reliability. Troubleshooting involves: identifying problems systematically (observe symptoms, gather information, isolate issues), understanding common issues (learn from experience, document problems), applying solutions methodically (test hypotheses, verify fixes), and documenting fixes (record solutions, share knowledge). Teams should develop troubleshooting procedures, practice troubleshooting, and learn from each problem. Good troubleshooting saves time and prevents recurring issues. Troubleshooting is skill that improves with experience.

**Common Robot Issues:**
Teams encounter various robot issues. Common issues include: electrical problems (disconnects, power issues, sensor failures), mechanical problems (binding, wear, breakage), software problems (crashes, logic errors, performance issues), and integration problems (components not working together). Teams should understand common issues, develop solutions, and maintain spare parts for quick fixes. Common issues often have known solutions - teams should research and document solutions. Understanding common issues helps teams troubleshoot quickly and effectively.

**Preventive Maintenance:**
Preventive maintenance prevents failures before they occur. Maintenance activities include: regular inspections (check for wear, damage, loose connections), cleaning (remove debris, clean mechanisms), lubrication (lubricate moving parts when needed), part replacement (replace worn parts before failure), and system updates (update firmware, software). Teams should establish maintenance schedules, perform maintenance regularly, and document maintenance activities. Preventive maintenance is more efficient than reactive repairs. Good maintenance prevents competition failures.

**Repair Strategies:**
Effective repair strategies minimize downtime. Strategies include: quick diagnosis (identify problem quickly), efficient repairs (fix efficiently, test thoroughly), spare parts inventory (maintain critical spares), repair documentation (document repairs, learn from issues), and backup plans (have alternatives when repairs take time). Teams should practice repairs, maintain spare parts, and develop repair procedures. Good repair strategies enable teams to fix problems quickly during competition. Teams should be prepared for common failures.

**Systematic Troubleshooting Process:**
Systematic process improves troubleshooting effectiveness. Process involves: problem identification (what's wrong?), information gathering (symptoms, recent changes, error messages), hypothesis formation (what could cause this?), testing (test hypotheses, verify causes), solution implementation (apply fix, test solution), and documentation (record problem and solution). Teams should follow systematic process, avoid jumping to conclusions, and test solutions thoroughly. Systematic troubleshooting is more effective than random attempts. Teams should develop troubleshooting skills through practice.
"""
            
        case "Game & Season":
            return """
**Current Season Overview:**
Each FTC season runs from September through April, with game reveal typically in early September. The current season (2025-2026) features DECODE™ presented by RTX, part of the FIRST AGE™ season presented by Qualcomm. Teams have approximately 6-8 weeks of build season to design, build, and program robots before competitions begin in November/December.

**Season Timeline:**
• September: Game reveal and manual release
• September-October: Build season (design and construction)
• November-April: Competition season (qualifying tournaments, championships)
• April: FIRST Championship (world championship event)

**Game Manual Structure:**
The Game Manual is divided into Part 1 (Game Rules) and Part 2 (Robot Rules). Part 1 covers the game challenge, field setup, scoring systems, and match procedures. Part 2 covers robot construction rules, size/weight constraints, part legality, and inspection requirements. Teams must understand both parts thoroughly to compete successfully.

**Field Setup and Construction:**
Competition fields are constructed from official field kits according to precise specifications. Field dimensions are standardized (12' x 12' playing field), and field elements must be placed exactly as specified. Teams can purchase field kits to practice on official fields, which is highly recommended for accurate testing. Field construction requires attention to detail - incorrect field setup affects robot performance and can cause rule violations.

**Scoring Systems:**
Each game has detailed scoring systems with point values for different actions. Understanding scoring is critical for strategic robot design and match play. Teams should calculate maximum possible scores, identify high-value actions, and prioritize scoring opportunities. Scoring often includes bonuses for specific conditions or combinations of actions.

**Competition Structure:**
FTC competitions follow standard structure: qualification matches (round-robin format, typically 5-6 matches per team), alliance selection (top teams choose partners), and elimination matches (playoff bracket). Teams earn ranking points (RP) and tiebreaker points based on match performance. Top teams advance to higher-level competitions.
"""
            
        case "Competition":
            return """
**Competition Types and Levels:**
FTC competitions are organized at multiple levels. Qualifying tournaments are typically one-day events with 12-24 teams. Regional/State championships are typically two-day events with 24-48 teams. FIRST Championship is the world championship event featuring top teams globally. Teams progress through levels by winning awards or qualifying through performance.

**Competition Registration:**
Registration opens in May for following season and typically closes in October. Registration requires team number, payment of fees ($275-$500 depending on region), completion of youth protection requirements, and submission of team information. Teams should register early to secure preferred competition dates. Registration system allows teams to manage rosters, update information, and register for specific competitions.

**Match Structure and Procedures:**
Matches are 2 minutes 30 seconds total: 30-second autonomous period (no driver control), 2-minute TeleOp period (driver control allowed), and endgame period (final 30 seconds with special rules). Matches involve two alliances (Red and Blue), each with two teams. Alliances compete to score more points than opponents. Match results determine ranking points and tiebreaker points.

**Alliance Selection Process:**
After qualification matches, top teams participate in alliance selection. First pick teams (typically top 4) choose first partner. Second pick teams choose second partner. Alliance selection is strategic - teams should research potential partners, evaluate compatibility, and make informed choices. Being selected as alliance partner is honor and recognition of team's capabilities.

**Competition Day Procedures:**
Competition day includes: arrival and check-in, pit setup, robot inspection, driver meeting, practice matches (if available), qualification matches, alliance selection (if qualified), elimination matches (if selected), and awards ceremony. Teams must follow competition-specific procedures, attend required meetings, and be ready for matches on schedule. Time management is critical - teams must balance match preparation, robot maintenance, scouting, and rest.
"""
            
        default:
            return """
**Comprehensive Technical Information:**
This section provides detailed technical information about \(title). The content covers technical specifications, implementation guides, best practices, troubleshooting procedures, and advanced techniques relevant to this topic.

**Key Concepts:**
Understanding the fundamental concepts is essential for effective implementation. This includes theoretical foundations, practical applications, and real-world considerations that affect success.

**Implementation Guide:**
Step-by-step implementation involves planning, preparation, execution, and validation. Teams should follow systematic approaches, test thoroughly, and iterate based on results.

**Best Practices:**
Proven best practices help teams avoid common mistakes and achieve better results. These practices are based on experience from successful teams and competition performance.

**Troubleshooting:**
Common issues and solutions help teams resolve problems quickly. Understanding typical failure modes and solutions enables efficient problem-solving during competition.

**Advanced Techniques:**
Advanced techniques provide competitive advantages for experienced teams. These techniques require solid fundamentals and should be learned gradually.
"""
        }
    }
}

