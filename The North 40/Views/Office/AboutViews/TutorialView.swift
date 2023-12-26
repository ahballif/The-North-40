//
//  TipsView.swift
//  The North 40
//
//  Created by Addison Ballif on 10/8/23.
//

import SwiftUI
import YouTubePlayerKit

struct TutorialView: View {
    
    @StateObject private var youTubePlayer: YouTubePlayer = YouTubePlayer(source: .video(id: "e9lqaH2exaI?si=tvRd45v0hol8WMNz"), configuration: .init(autoPlay: true))
    
    var body: some View {
        GeometryReader {geometry in
        
        ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Using the North 40 App").font(.largeTitle)
                    
                    YouTubePlayerView(self.youTubePlayer).frame(height:geometry.size.width/4.0*3.0)
                    body("(Don't read this unless you want to; just watch the video instead.)")
                    VStack(alignment: .leading, spacing: 20){
                        VStack(alignment: .leading, spacing: 20){
                            section("The To-Do View")
                            body("The To-Do View is where all your to-do's are displayed. The To-Do View has two different sorting modes. Press the icon in the upper right to toggle between the two sorting modes. ")
                            body("The first sorting mode lists all scheduled to-do items in order. When in this first sorting mode scheduled to-do items are listed in order on the main screen. Unscheduled to-do items are listed in the inbox. The inbox holds your to-do items until you are ready to schedule them for a specific time. Next to the inbox is the bucketlist. This is a place where you can put unscheduled to-do items that you are not ready to schedule. While in the inbox, you can swipe to move a to-do item to the bucketlist. ")
                            body("The second sorting mode lists all to-do items by the goals they are attached to. The list will display all scheduled and unscheduled to-do items. If a to-do is repeating, only the next future occurance will be shown. To-do items which are not attached to a goal are listed first, and then a section is given for each goal that has to-do's attached to it. ")
                            body("Reportables can also be displayed in your to-do list by toggling this feature in settings.")
                        }
                        VStack(alignment: .leading, spacing: 20) {
                            section("Types of Events")
                            body("There are five different types of events in the North 40 App. All 5 types of events can be displayed in the Daily and Weekly Planner views, as well as be attached to goals and people. ")
                            
                            subsection("Non-Reportable")
                            body("The Non-Reportable type of event is the simplest type of event in the North 40 App. It can be used to schedule events in the planner but has no special attributes. ")
                            subsection("Reportable")
                            body("The Reportable type of event is an event that invites you to give a short report and summary of how the event went once the event is in the past. There are 4 status options, Unreported, Skipped, Attempted, and Happened. Once a reportable event has moved to the past, it becomes unreported. In addition to updating the status you also have the option to write a short summary. ")
                            subsection("To-Do")
                            VStack(alignment: .leading, spacing: 20) {
                                body("To-Do events are events with only two status options. To-Do events are shown on the to-do view, and are also shown on the planner when scheduled. (There is a setting option which allows reportable type events to also be shown on the to-do view, making them an extended form of a To-Do type.)")
                                subsection("Radar Event")
                                body("Radar events are used for the purpose of making notes in the planner that may be useful to know about. They are displayed in the background of the planner views and can be toggled on or off. ")
                                
                                subsection("Backup Event")
                                body("Backup events allow you to make a \"plan B\" in your schedule. They can also be hidden from the planner views until needed. ")
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 20) {
                            section("The Daily Planner View")
                            
                            body("The Daily Planner is your primary tool for scheduling and making plans. Any events that are scheduled will show up. You can swipe to the left or to the right to change days. There are also arrows at the top of the screen which move the displayed day forward or back. All day events, goal due dates, birthdays, and holidays show up at the top of the daily planner. (Some of these can be hidden in settings.)")
                            body("Press anywhere on the background to add an event at that time. Click on events to edit them. You can enter dragging mode by long pressing and event on the planner. In drag mode you can drag this event to where you want to put it. Press anywhere to exit drag mode. ")
                            body("At the top left of the screen you there are two button which can be used to toggle Radar and Backup events. At the top right of the screen there is a button that allows you to search for an event by name, as well as a button which will toggle agenda mode, which displays all scheduled events in a list. ")
                            
                            
                            subsection("The Weekly Planner View")
                            body("On the iPad and the Mac, the North 40 App also has a Weekly Planner which can show 5 days at a time. All functionality is the same as the daily planner. On the iPad and Mac the daily planner can also be accessed from the dashboard, which shows the daily planner, to-do view, and goal list on a single page. ")
                        }
                        
                        
                        VStack(alignment: .leading, spacing: 20){
                            section("People")
                            body("The North 40 App allows you to enter in the people you know and work with in order to help them become a part of your planning. People can be attached to events and goals to help give you direction when you are planning. ")
                            body("When creating a new person you have the option of importing from contacts.")
                            section("Goals")
                            body("Entering your goals allows you to keep them in mind when you are planning your days and weeks. Events, notes, and people can be attached to goals. Each goal has a timeline which displays a complete history of what you have done in the past and what plans you have for the future. When adding a goal, you can choose to have it be a sub-goal working towards another more long term goal. ")
                        }
                        
                    }
                    
                    VStack(alignment: .leading, spacing: 20){
                        section("The Office Tab")
                        body("The Office tab provides several useful tools to help you stay organized. ")
                        
                        subsection("Notes")
                        body("Notes is a simple place to make and keep notes. Notes can be attached to goals or people and seen on their timeline. The notes page has a button in the top right to toggle between sorting alphabetically and sorting by date. Archived notes can be seen by clicking the button in the top left. Swipe on a note in the list to archive a note.")
                        body("On the goals page there is a small compass icon in the upper left. This opens up a note titled \"Life Vision\" which can be seen in the notes list. The compass icon accesses the note with this title, so if you change the name of that note, it will create a new one with the correct title.")
                        
                        subsection("Budget and Finance")
                        body("The North 40 App includes a simple budgeting system using envelopes and transactions. Envelopes are objects that contain a history of transactions. To create a new envelope press the plus button on the upper left. The double arrow button allows you to transfer money from one envelope to another. The balance for all envelopes is not calculated automatically, so you can press the Calculate All button to find your total balance. ")
                        VStack(alignment: .leading, spacing: 20){
                            subsection("Unreported Events")
                            body("There is a page in the office tab which displays all unreporting events, allowing you to find them quickly and fill out the report. The badge icon displays how many unreported events you currently have, encouraging you to keep an updated record.")
                            
                            subsection("Person Groups")
                            body("You can make groups of the people entered into your app in the person groups page. The list in the people tab is sorted by the groups you create here. When attaching people to an event you can also choose to attach an entire group.")
                            
                            subsection("Archived People")
                            body("If someone with whom you used to work is no longer in your circle, you can archive them to hide them from your main list. To archive someone, swipe to the left on the main person list in the people tab. Archived people can be viewed and unarchived from the page here in the office tab.")
                        }
                    }
                }.padding()
            }.onAppear {
                youTubePlayer.mute()
            }
        }
    }
    
    private func section(_ text: String) -> some View {
        return Text(text).font(.title).bold()
    }
    private func subsection(_ text: String) -> some View {
        return Text(text).font(.title2)
    }
    private func body(_ text: String) -> some View {
        return Text(text)
    }
}

struct TipsView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialView()
    }
}

