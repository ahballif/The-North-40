//
//  TipsView.swift
//  The North 40
//
//  Created by Addison Ballif on 10/8/23.
//

import SwiftUI

struct TutorialView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                let paddingHeight: CGFloat = 3
                
                Text("Using the North 40 App").font(.title)
                VStack(alignment: .leading) {
                    Text("To-Do List").font(.title3).padding(.vertical, paddingHeight)
                    Text("The To-Do tab lets you see all your To-Do items for today. Unfinished To-Do events are also shown. Press the + button to create a new To-Do. Unscheduled To-Do items are added to the inbox. From the inbox, you can schedule when you wish to complete the To-Do item, or you can swipe to add it to your bucklist for later. ").padding(.vertical, paddingHeight)
                    
                    Text("Daily Planner").font(.title3).padding(.vertical, paddingHeight)
                    Text("The daily planner is your most important tool for managing your time. Use it to plan your day or week and execute your plans with confidence. At the top left you can toggle hide/show radar events and backup events. At the top right you can change to the schedule view that shows all your daily events in list form.\n\nTo advance to the next day swipe left. To move to the previous day swipe right. You can also select the day using the date picker. All day events, goal due dates, and contact birthdays show up at the top of the daily scheduler. ").padding(.vertical, paddingHeight)
                    
                    Text("Event Types").bold().padding(.vertical, paddingHeight)
                    
                    Text("There are 5 types of events in the North 40 App. Reportable events allow you to give a review of how the event went after the event happens. Non-reportable events are basic events with no reporting. Radar events are events that allow you to put things in your calendar just FYI incase you want to keep track of something that might be happening. To-Do events are events with a checkmark to keep track of whether or not you have completed it. (Only To-Do events show in the To-Do tab.) Backup events are events that help you make a backup plan incase things don't go as expected. ")
                    
                    Text("People").font(.title3).padding(.vertical, paddingHeight)
                    
                    Text("Save your contacts for all the people you work with in the people tab. Each person has a contact page and a timeline page. The timeline page lets you view all the events to which that person is attached. ")
                }
                Text("Goals").font(.title3).padding(.vertical, paddingHeight)
                
                Text("Keep your goals in mind by entering them into the goals tab. Press the list button on the upper left to toggle between sorting by goal priority or sorting by goal hierarchy. A goal can have other goals attached to it as a sub-goal or as an end-goal. Goals can also have deadlines. The compass button opens a note where you can write your visions or life goals. This is a good place to record long term goals or visions for where you want to go in life. Press the graduation cap button on the upper right to view completed goals. Goals can be completed by giving a high five in the goal detail view. Like people, each goal has a timeline where you can view connected events. ")
                
                Text("Office").font(.title3).padding(.vertical, paddingHeight)
                Text("The office tab contains several tools to help you keep track of your life and stay organized. Keep notes in the notes section. Manage your finances using the budget tool. Report on unreported reportable-type events. Create person groups to organize your contacts. View your stats. See where you need to go with the map. View archived contacts. Customize your settings.").padding(.vertical, paddingHeight)
                
            }.padding()
        }
    }
}

struct TipsView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialView()
    }
}
