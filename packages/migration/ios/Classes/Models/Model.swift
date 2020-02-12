//
//  Model.swift
//
//  Created by Guilherme Assis on 24/01/16.
//

import Foundation
import CoreData

open class Model: NSManagedObject {
    
    //MARK: - Constructor
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    //MARK: - Get
    open class func getAll() -> [Model] {
        return getWithPropertiesToFetch("", predicate: "")
    }
    
    open class func getWithPredicate(_ predicate: String) -> [Model] {
        return getWithPropertiesToFetch("", predicate: predicate)
    }
    
    open class func getWithPropertiesToFetch(_ propertiesToFetch: String, predicate: String) -> [Model] {
        let request = fetchRequestWithPropertiesToFetch(propertiesToFetch, predicate: predicate, andFetchLimit: 20)
        
        do {
            let result = try AppHelper.shared.managedObjectContext.fetch(request)
            return result as! [Model]
        } catch {
            return NSArray() as! [Model]
        }
    }
    
    open class func fetchRequestWithPropertiesToFetch(_ propertiesToFetch: String, predicate: String, andFetchLimit: NSInteger) -> NSFetchRequest<NSFetchRequestResult> {
        
        let request = NSFetchRequest<NSFetchRequestResult>()
        let entity  = NSEntityDescription.entity(forEntityName: String(describing: self), in: AppHelper.shared.managedObjectContext)
        
        request.entity = entity
        request.propertiesToFetch = propertiesToFetchForString(propertiesToFetch)
        request.predicate = predicateForStringWithFormat(predicate)
        
        return request
    }
    
    //MARK: - Save
    open class func saveAll(){
        do {
            try AppHelper.shared.managedObjectContext.save()
        } catch {
            print("Model.ManagedObjectContext.saveAll()")
        }
    }
    
    open func save(){
        do {
            try AppHelper.shared.managedObjectContext.save()
        } catch {
            print("Model.ManagedObjectContext.save()")
        }
    }
    
    //MARK: - Delete
    open func delete(){
        do {
            AppHelper.shared.managedObjectContext.delete(self)
            try AppHelper.shared.managedObjectContext.save()
        } catch {
            print("Model.ManagedObjectContext.delete()")
        }
    }
    
    open class func deleteWithPredicate(_ predicate: String) {
        let allObjs = getWithPredicate(predicate)
        for model: Model in allObjs {
            AppHelper.shared.managedObjectContext.delete(model)
        }
        do {
            try AppHelper.shared.managedObjectContext.save()
        } catch {
            print("Model.ManagedObjectContext.deleteWithPredicate()")
        }
    }
    
    //MARK: - RollBack
    open class func rollback() {
        AppHelper.shared.managedObjectContext.rollback()
    }
    
    //MARK: - Truncate
    open class func truncate() {
        let allObjs = getAll()
        for model: Model in allObjs {
            AppHelper.shared.managedObjectContext.delete(model)
        }
        
        do {
            try AppHelper.shared.managedObjectContext.save()
        } catch {
            print("Model.ManagedObjectContext.truncate()")
        }
    }
    
    //MARK: - Private Methods
    class func propertiesToFetchForString(_ stringPropertiesToFetch: String) -> [AnyObject]? {
        if !(stringPropertiesToFetch == "") {
            let properties: [AnyObject] = stringPropertiesToFetch.replacingOccurrences(of: " ", with: "").components(separatedBy: ",") as [AnyObject]
            return properties
        }
        return nil
    }
    
    class func predicateForStringWithFormat(_ stringWithFormatPredicate: String) -> NSPredicate? {
        if !(stringWithFormatPredicate == ""){
            return NSPredicate(format: stringWithFormatPredicate, argumentArray: nil)
        }
        return nil
    }
}
