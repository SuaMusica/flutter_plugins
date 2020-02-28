import Foundation
import CoreData


class LoggedUser: Model {
    init() {
        let entityDescription = NSEntityDescription.entity(forEntityName: "LoggedUser", in: AppHelper.shared.managedObjectContext)
        super.init(entity: entityDescription!, insertInto: AppHelper.shared.managedObjectContext)
    }
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        let entityDescription = NSEntityDescription.entity(forEntityName: "LoggedUser", in: AppHelper.shared.managedObjectContext)
        super.init(entity: entityDescription!, insertInto: AppHelper.shared.managedObjectContext)
    }
    
    convenience init(userId: String, name: String?, downloads: String? = "0", plays: String? = "0", uploads: String? = "0",
                     instagram: String?, twitter: String?, sobre: String?, pictureUrl: String?, site: String?,
                     facebook: String?, whatsapp: String?, telefone: String?, adFirstTime: String?, adTime: String?) {
        self.init()
        self.userId = userId
        self.name = name
        self.downloads = downloads
        self.plays = plays
        self.uploads = uploads
        self.instagram = instagram
        self.twitter = twitter
        self.sobre = sobre
        self.pictureUrl = pictureUrl
        self.site = site
        self.facebook = facebook
        self.whatsapp = whatsapp
        self.telefone = telefone
        self.adFirstTime = adFirstTime
        self.adTime = adTime
    }
}

extension LoggedUser {
    @NSManaged var facebookId: String?
    @NSManaged var name: String?
    @NSManaged var lastName: String?
    @NSManaged var firstName: String?
    @NSManaged var pictureUrl: String?
    @NSManaged var email: String?
    @NSManaged var userId: String?
    @NSManaged var plays: String?
    @NSManaged var downloads: String?
    @NSManaged var uploads: String?
    @NSManaged var twitter: String?
    @NSManaged var instagram: String?
    @NSManaged var sobre: String?
    @NSManaged var whatsapp: String?
    @NSManaged var telefone: String?
    @NSManaged var facebook: String?
    @NSManaged var site: String?
    @NSManaged var adFirstTime: String?
    @NSManaged var adTime: String?
}