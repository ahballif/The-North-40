//
//  AboutView.swift
//  The North 40
//
//  Created by Addison Ballif on 10/8/23.
//

import SwiftUI

struct AboutView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @Environment(\.dismiss) private var dismiss
    private let hasDoneBar: Bool
    
    init (hasDoneBar: Bool = false) {
        self.hasDoneBar = hasDoneBar
    }
    
    var body: some View {
        
        VStack {
            if hasDoneBar {
                HStack {
                    Spacer()
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            HStack {
                Text("The North 40").font(.title)
                Spacer()
            }
            ScrollView {
                VStack{
                    if colorScheme == .dark {
                        Image("N40Black")
                            .resizable()
                            .scaledToFit()
                            .colorInvert()
                    } else {
                        Image("N40Black")
                            .resizable()
                            .scaledToFit()
                    }
                }.frame(maxHeight: 250)
                VStack(alignment: .leading, spacing: 20) {
                    
                    Text("Welcome to North 40, your daily planner and goal-setting app. Inspired by the concept of the North 40 acres, known as the most fertile and productive land on a farm, this app is here to help you sow the seeds of success. From setting SMART objectives to providing a roadmap for your daily tasks, North 40 is designed to help you navigate the vast landscape of your life with focus and purpose. Let every day bring you a step closer to the fertile ground of your aspirations.")
                    
                    
                    Text("Consider the following story. In the countryside, farmer Thomas set out to repair his cornfield fence on the old north 40. Shortly after going to work, he noticed the barn door's creaky hinges. Halting the fence work, he addressed the door, only to spot the squeaky water pump nearby. With tools in hand, he redirected his attention to the pump, forgetting about both the fence and the barn door. Shortly after getting started, Thomas's gaze shifted again to a leaky roof. As he attempted to patch the roof, a broken plow in the adjacent field called for immediate fixing. Distracted yet dutiful, Thomas moved from task to task, each one preventing him from completing the previous. As the sun dipped below the horizon, Thomas surveyed his farm, a mosaic of unfinished projects. The fence still in disrepair, the barn door creaking, the water pump squeaking, the leaky roof dripping, and the broken plow left untouched. Despite a day of constant effort, Thomas couldn't ignore the stark reality – none of the tasks were complete. ")
                    
                    //Text("Today on the farm started with a singular goal – repair the cornfield fence. However, as I began, the creaky hinges of the barn door caught my attention. Halted the fence work and tended to the door. Midway through, I noticed the nearby squeaky water pump; my focus shifted once again, leaving both the fence and barn door forgotten. However, my eyes fixed on a leaky roof demanding immediate attention. Attempting to patch it up led me to the adjacent field, where a broken plow awaited urgent fixing. As the sun dipped below the horizon, I surveyed the farm – a patchwork of unfinished projects. The fence remained in disrepair, the barn door continued its creaking symphony, the water pump occasionally squeaked, the leaky roof persisted in dripping, and the broken plow stood untouched. A day of constant effort, yet the stark reality lingers – none of the tasks are complete.").padding(.horizontal)
                    
                    
                    Text("You may have heard a similar story before. Perhaps you have experienced it. What derailed the farmer from his goal to cut hay? Despite doing many good things the farmer did not get anything done because he wasn't focused on his goal. He failed to organize his priorities and make an effective plan.")
                    
                    
                    Rectangle().frame(height: 1)
                    Text("The North 40 App is intended to help you get things done by setting goals and making plans. It includes a daily planner, a contact book that links with calendar events, a goal board, and several other tools to help you stay focused on what is most important in your life.")
                    
                    
                }
                Rectangle().frame(height: 1)
                NavigationLink(destination: TutorialView()) {
                    Text("Using the App")
                }
                Rectangle().frame(height: 1)
                Button("Tips on Goal Setting") {
                    if let yourURL = URL(string: "https://ahballif.github.io/North40/goalSetting.html") {
                            UIApplication.shared.open(yourURL, options: [:], completionHandler: nil)
                        }
                }
                
            }
        }.padding()
        
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
