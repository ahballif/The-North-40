//
//  Event+CoreDataClass.swift
//  The North 40
//
//  Created by Addison Ballif on 8/11/23.
//
//

import Foundation
import CoreData
import SwiftUI


public class N40Event: NSManagedObject {

    public var renderIdx: Int? //For showing on the calendar. It will be stored here to allow other events to look at each other.
    public var indicesOfOthers: [Int] = [] //an array containing the render indices of all the overlapping events.
    
    public var getHighestEventIdx: Int {
        //returns 0 if there are no overlapping events
        var highest = 0
        for index in (indicesOfOthers) {
            //assuming overlappingEvents includes this event because of how it is assigned elsewhere. 
            if index > highest {
                highest = index
            }
        }
        return highest
    }
}

public class EventRenderCalculator {
    //functions for calculating how events render on the calendar
    public static func precalculateEventColumns (_ allEvents: [N40Event]) -> EmptyView {
        //precalculates the event render indices for all events before they are iterated through one at a time.
        assignLowestRenderIndices(allEvents: allEvents)
        assignOverlappingEventsArrays(allEvents: allEvents)
        
        return EmptyView()
    }
    
    private static func assignOverlappingEventsArrays (allEvents: [N40Event]) {
        //this function makes sure that every event knows which events it is overlapping with.
        
        //start by reseting them all to empty
        for eachEvent in allEvents {
            eachEvent.indicesOfOthers = [] //start with it only overlapping with itself.
        }
                
        //now go through each one and determine if another event is overlapping with it.
        for eachEvent in allEvents {
            for eachOtherEvent in allEvents {
                if doEventsOverlap(event1: eachEvent, event2: eachOtherEvent) {
                    eachEvent.indicesOfOthers.append(eachOtherEvent.renderIdx ?? 0) //incase eachOtherEvent is not contained in eachOtherEvent.overlappingEvents
                    eachEvent.indicesOfOthers += eachOtherEvent.indicesOfOthers //add the ones that this eachEvent cant see
                    
                    eachOtherEvent.indicesOfOthers.append(eachEvent.renderIdx ?? 0)
                    eachOtherEvent.indicesOfOthers += eachEvent.indicesOfOthers
                }
            }
        }
        
        //remove duplicates
        for eachEvent in allEvents {
            eachEvent.indicesOfOthers = Array(Set(eachEvent.indicesOfOthers))
        }
        
        //now all events should have an array of all events that relate to them.
        
    }

    private static func assignLowestRenderIndices (allEvents: [N40Event]) {
        //this function lets each event find it's render index based on the lowest untake one.
        
        //first reset all
        for eachEvent in allEvents {
            eachEvent.renderIdx = -1
        }
        
        //now let each one find the lowest untaken
        for eachEvent in allEvents {
            let directlyOverlappingEvents = allEventsAtTime(event: eachEvent, allEvents: allEvents)
            
            eachEvent.renderIdx = getLowestUntakenEventIndex(overlappingEvents: directlyOverlappingEvents)
        }
        
        //now each event should be in a good spot.
    }

    // FUNCTIONS USED FOR RENDERING THE EVENTS

    private static func allEventsAtTime(event: N40Event, allEvents: [N40Event]) -> [N40Event] {
        //returns an array of events that are in that location
        var eventsAtTime: [N40Event] = []
        
        allEvents.forEach {eachEvent in
            if doEventsOverlap(event1: event, event2: eachEvent) {
                eventsAtTime.append(eachEvent)
            }
        }
        
        return eventsAtTime
    }

    private static func doEventsOverlap (event1: N40Event, event2: N40Event) -> Bool {
        var answer = false
        
        
        let minDuration = (DailyPlanner.minimumEventHeight/UserDefaults.standard.double(forKey: "hourHeight")*60.0)
        let testDuration = Int(event1.duration) > Int(minDuration) ? Int(event1.duration) : Int(minDuration)
        
        
        let startOfInterval = event1.startDate.zeroSeconds
        var endOfInterval = Calendar.current.date(byAdding: .minute, value: testDuration, to: event1.startDate.zeroSeconds) ?? startOfInterval
        
        if endOfInterval.timeIntervalSince(startOfInterval) > 0 {
            endOfInterval = Calendar.current.date(byAdding: .second, value: -1, to: endOfInterval) ?? endOfInterval
        } //subtract a second from the end of the interval to make it less confusing.
        
        
        let eventTestDuration = Int(event2.duration) > Int(minDuration) ? Int(event2.duration) : Int(minDuration)
        
        let eventStartOfInterval = event2.startDate.zeroSeconds
        var eventEndOfInterval = Calendar.current.date(byAdding: .minute, value: eventTestDuration, to: eventStartOfInterval) ?? eventStartOfInterval
        
        if eventEndOfInterval.timeIntervalSince(eventStartOfInterval) > 0 {
            eventEndOfInterval = Calendar.current.date(byAdding: .second, value: -1, to: eventEndOfInterval) ?? endOfInterval
        } //subtract a second from the end of the interval to make it less confusing.
        
        
        //  considering the ranges are: [x1:x2] and [y1:y2]
        // x1 <= y2 && y1 <= x2
        if ( startOfInterval <= eventEndOfInterval && eventStartOfInterval <= endOfInterval) {
            answer = true
        }
        
        return answer
        
    }


    private static func numberOfEventsAtTime(event: N40Event, allEvents: [N40Event]) -> Int {
        let allEventsAtTime = allEventsAtTime(event: event, allEvents: allEvents)
        return allEventsAtTime.count
    }

    private static func getLowestUntakenEventIndex (overlappingEvents: [N40Event]) -> Int {
        
        var takenIndices: [Int] = []
        
        //We need to iterate in accending order, so first just get all the indices
        overlappingEvents.forEach {eachEvent in
            takenIndices.append(eachEvent.renderIdx ?? -1)
        }
        takenIndices.sort()
        
        var lowestUntakeIdx = 0
        
        //now we can iterate through them
        takenIndices.forEach {idx in
            if idx == lowestUntakeIdx {
                lowestUntakeIdx += 1
            }
        }
        
        return lowestUntakeIdx
        
    }

    private static func getHighestEventIndex (allEvents: [N40Event], from: Date, to: Date) -> Int {
        
        var relevantEvents: [N40Event] = []
        
        let refTo = Calendar.current.date(bySetting: .second, value: 0, of: to) ?? to
        let refFrom = Calendar.current.date(bySetting: .second, value: 0, of: from) ?? from
        
        for eachEvent in allEvents {
            
            
            let endDate = Calendar.current.date(bySetting: .second, value: 0, of: Calendar.current.date(byAdding: .minute, value: getCellHeight(eachEvent), to: eachEvent.startDate) ?? eachEvent.startDate) ?? eachEvent.startDate
            let startDate = Calendar.current.date(bySetting: .second, value: 0, of: eachEvent.startDate) ?? eachEvent.startDate
            
            
            if (startDate >= refFrom && startDate < refTo) || (endDate > refFrom && endDate <= refTo) || (startDate < refFrom && endDate > refTo) || (startDate >= refFrom && endDate <= refTo) {
                //if the start time is within the interval, or the end time is within the interval, or the start time is before and the end time is after
                relevantEvents.append(eachEvent)
            }
        }
        
        var greatestEventIndex = 0
        //now find the greatestEventIndex
        for eachRelevantEvent in relevantEvents {
            if eachRelevantEvent.renderIdx ?? 0 > greatestEventIndex {
                greatestEventIndex = eachRelevantEvent.renderIdx ?? greatestEventIndex
            }
        }
        
        return greatestEventIndex
        
    }

    private static func getCellHeight(_ event: N40Event) -> Int {
        //Returns the true cell height in minutes
        //ex. if duration == 0, the cell still has some minimum width.
        let minDuration = (DailyPlanner.minimumEventHeight/UserDefaults.standard.double(forKey: "hourHeight")*60.0)
        let testDuration = Int(event.duration) > Int(minDuration) ? Int(event.duration) : Int(minDuration)
        return testDuration
    }

    private static func getTestDuration(duration: Int) -> Int {
        let minDuration = (DailyPlanner.minimumEventHeight/UserDefaults.standard.double(forKey: "hourHeight")*60.0)
        return Int(duration) > Int(minDuration) ? Int(duration) : Int(minDuration)
        
    }

}



