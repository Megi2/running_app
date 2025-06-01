//
//  WorkoutEntity.swift
//  running_app
//
//  Created by 전진하 on 6/1/25.
//


import Foundation
import CoreData

@objc(WorkoutEntity)
public class WorkoutEntity: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutEntity> {
        return NSFetchRequest<WorkoutEntity>(entityName: "WorkoutEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var duration: Double
    @NSManaged public var distance: Double
    @NSManaged public var averageHeartRate: Double
    @NSManaged public var averagePace: Double
    @NSManaged public var averageCadence: Double
    @NSManaged public var dataPointsData: Data?

}

extension WorkoutEntity : Identifiable {

}