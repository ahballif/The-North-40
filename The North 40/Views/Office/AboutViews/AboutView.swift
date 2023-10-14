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
                VStack(alignment: .leading) {
                    Text("A farmer started his day setting out to work on the old north 40. The following is his journal entry for the day. ")
                    Text("Decided to cut hay. Started to harness up the horses and found that the harness was broken. I took it to the granary to repair it and noticed some empty sacks lying around. The sacks were a reminder that some potatoes in the cellar needed the sprouts removed. I went to the cellar to do the job and noticed that the room needed sweeping. I went to the house to get a broom and saw the wood box was empty. I went to the woodpile and noticed some ailing chickens. They were such sad-looking things that I decided to get some medicine for them. Since I was out of medicine, I jumped into the car and headed for the drugstore. On the way, I ran out of gas.").padding()
                    
                    
                    Text("You may have heard this story or one like it. Perhaps you have felt like that before. Did the farmer get anything done? What derailed the farmer from his goal to cut hay? Despite doing many good things the farmer did not get anything done because he wasn't focused on his goal. ")
                    
                    
                    Rectangle().frame(height: 1)
                    Text("The North 40 App is intended to help you get things done by setting goals and making plans. It includes a daily planner, a contact book that links with calendar events, a goal board, and several other tools to help you stay focused on what is most important in your life.")
                    
                    
                }
                Rectangle().frame(height: 1)
                NavigationLink(destination: TutorialView()) {
                    Text("Using the App")
                }
                Rectangle().frame(height: 1)
                NavigationLink(destination: GoalTipsView()) {
                    Text("Tips for Setting Goals")
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
