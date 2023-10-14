//
//  GoalTipsView.swift
//  The North 40
//
//  Created by Addison Ballif on 10/8/23.
//

import SwiftUI

struct GoalTipsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Tips for Goal Setting").font(.title).padding(.vertical)
                
                Text("A goal is an anticipated accomplishment. The value of a goal helps determine its priority. Prioritizing goals means to put them in a desired order. A calendar helps us schedule all that we need to accomplish.")
                Text("\nMost successful people set goals. Goal setting helps us plan and gives direction to our lives.")
                
                
                Text("\nJohn H Vandenberg once said, \"I feel that goal-setting is absolutely necessary for happy living. But the goal is only part of the desired procedures. We need to know which roads to take to reach the goal. In many cases we set far-reaching goals but neglect the short-range ones. With such short-range plans, we need self-discipline in our actions—study when it is time to study, sleep when it is time to sleep, read when it is time to read, and so on—not permitting an undesirable overlap, but getting our full measure of rewards and blessings from the time we invest in a particular activity.\"\n\nThis kind of goal setting is best achieved when you plan everything that you do so that you know when you have time to work on certain things. For example, enter in when you need to eat, when you need to sleep, when you need to do homework, when you need to spend time with family. Plan when to start long term projects, and plan the time that you are going to work on it.")
                
                Text("\nTo learn more about goal setting you can read more [here.](https://www.churchofjesuschrist.org/study/manual/the-gospel-and-the-productive-life-teacher-manual-2018/chapter-3?lang=eng#subtitle1)")
            }
        }.padding()
    }
}

struct GoalTipsView_Previews: PreviewProvider {
    static var previews: some View {
        GoalTipsView()
    }
}
