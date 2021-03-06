import XCTest
import RealmSwift
@testable import BackgroundRealm


class Realm_Background_Tests: XCTestCase
{
    override func setUp() {
        super.setUp()
        
        Realm.Configuration.backgroundConfiguration = nil
        staticBackgroundWriteToken = nil
        instanceBackgroundWriteToken = nil
    }
    
    func testStaticWriteInBackgroundWithNoConfiguration() {
        let expectError = expectation(description: "We should get a BackgroundRealm.Error.noBackgroundConfiguration from calling `Realm.writeInBackground` with no configuration set")
        
        Realm.writeInBackground { (_, error) in
            defer { expectError.fulfill() }
            
            switch error {
            case .some(let value):
                XCTAssert(value == .noBackgroundConfiguration, "Since we haven't set a background configuration, we should get a BackgroundRealm.Error.noBackgroundConfiguration back from writeInBackground")
            default:
                XCTFail("We haven't got the right error here")
            }
        }
        
        wait(for: [expectError],
             timeout: 3)
    }
    
    func testInstanceWriteInBackgroundWithNoConfiguration() {
        let expectRealm = expectation(description: "We should get a Realm instance back from calling `realm.writeInBackground` with the default configuration")
        
        do {
            let realm = try Realm()
            realm.writeInBackground { (realm, error) in
                defer { expectRealm.fulfill() }
                
                XCTAssertNil(error, "We should be able to get a background Realm with no errors, but got one: \(error!)")
                XCTAssertNotNil(realm, "We should be able to get a background Realm with no errors")
            }
        } catch {
            XCTFail("\(error)")
            expectRealm.fulfill()
        }
        
        wait(for: [expectRealm],
             timeout: 3)
    }
    
    func testStaticWriteInBackgroundWithFileURL() {
        let expectRealm = expectation(description: "We should get a Realm instance back from calling `Realm.writeInBackground` with a background file URL set")
        
        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testStaticWriteInBackgroundWithFileURL.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")
        
        Realm.writeInBackground(fileURL: url!) { (realm, error) in
            defer { expectRealm.fulfill() }
            
            XCTAssertNil(error, "We should be able to get a background Realm with no errors, but got one: \(error!)")
            XCTAssertNotNil(realm, "We should be able to get a background Realm with no errors")
            XCTAssertNotNil(realm?.configuration.fileURL, "The background realm's configuration shouldn't be empty")
            XCTAssertEqual(realm?.configuration.fileURL, url, "The background realm's URL should be equal to \(url!)")
        }
        
        wait(for: [expectRealm],
             timeout: 3)
    }
    
    func testInstanceWriteInBackgroundWithFileURL() {
        let expectRealm = expectation(description: "We should get a Realm instance back from calling `realm.writeInBackground` with a background file URL set")
        
        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testInstanceWriteInBackgroundWithFileURL.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")
        
        do {
            let realm = try Realm(fileURL: url!)
            realm.writeInBackground { (realm, error) in
                defer { expectRealm.fulfill() }
                
                XCTAssertNil(error, "We should be able to get a background Realm with no errors, but got one: \(error!)")
                XCTAssertNotNil(realm, "We should be able to get a background Realm with no errors")
                XCTAssertNotNil(realm?.configuration.fileURL, "The background realm's configuration shouldn't be empty")
                XCTAssertEqual(realm?.configuration.fileURL, url!, "The background realm's URL should be equal to \(url!)")
            }
        } catch {
            XCTFail("\(error)")
            expectRealm.fulfill()
        }
        
        wait(for: [expectRealm],
             timeout: 3)
    }
    
    func testStaticWriteInBackgroundWithConfiguration() {
        let expectRealm = expectation(description: "We should get a Realm instance back from calling `Realm.writeInBackground` with a background configuration set")
        
        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testStaticWriteInBackgroundWithConfiguration.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")
        
        Realm.Configuration.backgroundConfiguration = Realm.Configuration(fileURL: url!)
        Realm.writeInBackground { (realm, error) in
            defer { expectRealm.fulfill() }
            
            XCTAssertNil(error, "We should be able to get a background Realm with no errors, but got one: \(error!)")
            XCTAssertNotNil(realm, "We should be able to get a background Realm with no errors")
            XCTAssertNotNil(realm!.configuration.fileURL, "The background realm's configuration shouldn't be empty")
            XCTAssertEqual(realm!.configuration.fileURL!, Realm.Configuration.backgroundConfiguration!.fileURL!, "The background realm's URL should be equal to the one set on Realm.Configuration.backgroundConfiguration")
        }
        
        wait(for: [expectRealm],
             timeout: 3)
    }
    
    func testInstanceWriteInBackgroundWithConfiguration() {
        let expectRealm = expectation(description: "We should get a Realm instance back from calling `realm.writeInBackground` with a background configuration set")
        
        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testInstanceWriteInBackgroundWithConfiguration.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")
        
        Realm.Configuration.backgroundConfiguration = Realm.Configuration(fileURL: url!)
        do {
            let realm = try Realm(fileURL: url!)
            realm.writeInBackground { (realm, error) in
                defer { expectRealm.fulfill() }
                
                XCTAssertNil(error, "We should be able to get a background Realm with no errors, but got one: \(error!)")
                XCTAssertNotNil(realm, "We should be able to get a background Realm with no errors")
                XCTAssertNotNil(realm!.configuration.fileURL, "The background realm's configuration shouldn't be empty")
                XCTAssertEqual(realm!.configuration.fileURL!, Realm.Configuration.backgroundConfiguration!.fileURL!, "The background realm's URL should be equal to \(url!)")
            }
        } catch {
            XCTFail("\(error)")
            expectRealm.fulfill()
        }
        
        wait(for: [expectRealm],
             timeout: 3)
    }
    
    var staticBackgroundWriteToken: NotificationToken?
    
    func testReceivingChangesFromStaticBackgroundWrite() {
        let expectWrite = expectation(description: "We should get a notification from a write transaction initated by a call to `Realm.writeInBackground`")
        
        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testReceivingChangesFromStaticBackgroundWrite.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")
        
        Realm.Configuration.backgroundConfiguration = Realm.Configuration(fileURL: url!)
        
        let name = "TEST TEST"
        
        do {
            let realm = try Realm(configuration: Realm.Configuration.backgroundConfiguration!)
            realm.beginWrite()
            realm.deleteAll()
            try realm.commitWrite()
            
            staticBackgroundWriteToken = realm.objects(TestObject.self).observe({ (change) in
                switch change {
                case .error(let error):
                    XCTFail("\(error)")
                    expectWrite.fulfill()
                case .initial(_):
                    print("INITIAL")
                case .update(let collection, _, let insertions, _):
                    XCTAssertFalse(insertions.isEmpty, "We should have inserted a TestObject")
                    XCTAssertEqual(collection[insertions.first!].name, name, "We should have inserted a TestObject with the name '\(name)'")
                    expectWrite.fulfill()
                }
            })
        } catch {
            XCTFail("\(error)")
            expectWrite.fulfill()
        }
        
        Realm.writeInBackground { (realm, _) in
            let object = TestObject()
            object.name = name
            realm?.add(object)
        }
        
        wait(for: [expectWrite],
             timeout: 5)
    }
    
    var instanceBackgroundWriteToken: NotificationToken?
    
    func testReceivingChangesFromInstanceBackgroundWrite() {
        let expectWrite = expectation(description: "We should get a notification from a write transaction initated by a call to `realm.writeInBackground`")
        
        let url = Realm.Configuration.defaultConfiguration.fileURL?.deletingLastPathComponent().appendingPathComponent("testReceivingChangesFromInstanceBackgroundWrite.realm")
        XCTAssertNotNil(url, "The test realm URL shouldn't be nil")
        print("URL: \(url!)")
        
        Realm.Configuration.backgroundConfiguration = Realm.Configuration(fileURL: url!)
        
        let name = "TEST TEST"
        
        do {
            let realm = try Realm(configuration: Realm.Configuration.backgroundConfiguration!)
            realm.beginWrite()
            realm.deleteAll()
            try realm.commitWrite()
            
            instanceBackgroundWriteToken = realm.objects(TestObject.self).observe({ (change) in
                switch change {
                case .error(let error):
                    XCTFail("\(error)")
                    expectWrite.fulfill()
                case .initial(_):
                    print("INITIAL")
                case .update(let collection, _, let insertions, _):
                    XCTAssertFalse(insertions.isEmpty, "We should have inserted a TestObject")
                    XCTAssertEqual(collection[insertions.first!].name, name, "We should have inserted a TestObject with the name '\(name)'")
                    expectWrite.fulfill()
                }
            })
            
            realm.writeInBackground { (realm, _) in
                let object = TestObject()
                object.name = name
                realm?.add(object)
            }
        } catch {
            XCTFail("\(error)")
            expectWrite.fulfill()
        }
        
        wait(for: [expectWrite],
             timeout: 5)
    }
}
