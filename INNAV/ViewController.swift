import CoreData
import UIKit
import ARKit
import GameplayKit

class ViewController: UIViewController,ARSCNViewDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var drawBtn: UIButton!
    @IBOutlet weak var navigateBtn: UIButton!
    @IBOutlet weak var addPOIBtn: UIButton!
    
    @IBOutlet weak var stopnavbtn: UIButton!
    
    let configuration = ARWorldTrackingConfiguration()
    var tempNodeFlag = false
    var tempnavFlag = true
    var poiFlag = false
    var pathNodes = [SCNNode(),SCNNode()]
    var counter = 0
    var dictPlanes = [ARPlaneAnchor:Plane]()
    let rootTempNode = SCNNode()
    let rootPathNode = SCNNode()
    let rootConnectingNode = SCNNode()
    let rootNavigationNode = SCNNode()
    let rootPOINode = SCNNode()
    let myQueue = DispatchQueue(label: "myQueue", qos: .userInitiated)
    var showFloorMesh = false
    
    var pathGraph = GKGraph()
    let origin = SCNVector3Make(0, 0, 0)
    var tempYAxis = Float()
    
    var stringPathMap = [String:[String]]()
    var dictOfNodes = [String:GKGraphNode2D]()
    var poiNode = [String]()
    var strNode = String()
    var cameraLocation = SCNVector3()
    var poiName = [String]()
    var poiCounter = 0
    weak var timer: Timer?
  
    var name = String()
//
//    var container: NSPersistentContainer!
//
////    func save () {
////        let context = persistentContainer.viewContext
////        if context.hasChanges {
////          do {
////              try context.save()
////          } catch {
////              let nserror = error as NSError
////              fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
////          }
////        }
////      }
//
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//            if let nextVC = segue.destination as? ViewController {
//                nextVC.container = container
//            }
//        }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        guard container != nil else {
//                    fatalError("This view needs a persistent container.")
//                }
//        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.autoenablesDefaultLighting = true
        configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.sceneView.scene.rootNode.addChildNode(rootPathNode)
        self.sceneView.scene.rootNode.addChildNode(rootPOINode)
        self.sceneView.scene.rootNode.addChildNode(rootNavigationNode)
        self.sceneView.scene.rootNode.addChildNode(rootConnectingNode)
        //poiName.append("Place 1 - Red")
        //poiName.append("Place 2 - blue")
        
    }

    //
    // MARK: ARSCNViewDelegate Methods //
    //
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if showFloorMesh{
            DispatchQueue.main.async {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    let plane = Plane(anchor: planeAnchor)
                    node.addChildNode(plane)
                    self.dictPlanes[planeAnchor] = plane
                }
            }
        }
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        DispatchQueue.main.async {
            
            if let planeAnchor = anchor as? ARPlaneAnchor {
                let plane = self.dictPlanes[planeAnchor]
                plane?.updateWith(planeAnchor)
            }
            let hitTest = self.sceneView.hitTest(self.view.center, types: .existingPlaneUsingExtent)
            if self.tempNodeFlag && !hitTest.isEmpty {
                self.addTempNode(hitTestResult: hitTest.first!)
            }
            if self.poiFlag && !hitTest.isEmpty {
                self.addPointOfInterestNode(hitTestResult: hitTest.first!)
                self.poiFlag = false
            }
            guard let pointOfView = self.sceneView.pointOfView else { return }
            let transform = pointOfView.transform
            self.cameraLocation = SCNVector3(transform.m41, transform.m42, transform.m43)
        }
    }
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            self.dictPlanes.removeValue(forKey: planeAnchor)
        }
    }

    //Button Actions

    @IBAction func StartAction(_ sender: Any) {
        
        if tempNodeFlag {
            tempNodeFlag = false
            drawBtn.setTitle("SCAN", for: .normal)
            removeTempNode()
            pathNodes[0].position.y = pathNodes[1].position.y
            tempYAxis = pathNodes[0].position.y
            addPathNodes(n1: pathNodes[0].position,n2: pathNodes[1].position)
            counter = 0
            addPOIBtn.isHidden = false
        } else {
            tempNodeFlag = true
            drawBtn.setTitle("STOP", for: .normal)
            
        }
        
    }
    @IBAction func AddPOIAction(_ sender: Any) {
        
        
        
        let alertCtrlr = UIAlertController(title: "Point of Interest", message: nil , preferredStyle: .alert)
        let textField = UITextField()
        textField.placeholder = "Enter a name for POI"
        alertCtrlr.addTextField { (textField) in
            textField.placeholder = "Enter a name for POI"
        }
        
        let action = UIAlertAction(title: "Continue",
                                           style: .default) { [weak alertCtrlr] _ in
                                            guard let textFields = alertCtrlr?.textFields else { return }
                                            
            if let text = textFields[0].text {
                self.poiName.append(text)
                self.poiFlag = true
                self.poiCounter += 1
            }

        }

        alertCtrlr.addAction(action)
        self.present(alertCtrlr,animated:true,completion:nil)
        
        
    }
    func addPointOfInterestNode(hitTestResult:ARHitTestResult) {
       
        let transform = hitTestResult.worldTransform
        let thirdColumn = transform.columns.3
        
        let node = SCNNode(geometry:SCNCylinder(radius: 0.04, height: 1.7))
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        node.position = SCNVector3Make(thirdColumn.x, thirdColumn.y+0.85, thirdColumn.z)
        rootPOINode.addChildNode(node)
        
        let node2 = SCNNode(geometry:SCNBox(width: 0.25, height: 0.25, length: 0.25, chamferRadius: 0.01))
        
        let colours = ["red","blue","green"]
        let randomcolour = colours.randomElement()!
        node2.geometry?.firstMaterial?.diffuse.contents = UIImage(named: randomcolour)
        if (poiCounter == 2){
            self.navigateBtn.isHidden = false
        }

        node2.position = SCNVector3Make(thirdColumn.x, thirdColumn.y+1.5, thirdColumn.z)
        rootPOINode.addChildNode(node2)
        
        var minDistanc = Float()
        minDistanc = 1000
        var nearestNode = SCNNode()
        
        rootPathNode.enumerateChildNodes { (child, _) in
            if !isEqual(n1: origin, n2: child.position) {
                
                let dist0 = distanceBetween(n1: node.position, n2: child.position)
                if minDistanc>dist0 {
                    
                    minDistanc = dist0
                    nearestNode = child
                }
            }
        }
        stringPathMap["\(node.position)"] = ["\(nearestNode.position)"]
        poiNode.append("\(node.position)")
    }
    
    @IBAction func NavigateAction(_ sender: Any) {
        if tempnavFlag{
            self.drawBtn.isHidden = true
            let alertCtrlr = UIAlertController(title: "Select POI", message: nil , preferredStyle: .alert)
            
            timer?.invalidate()
            
            var x = 0
            for node in poiNode{
                //x=0
                let action = UIAlertAction(title: poiName[x], style: .default) { (alertAction) in
                    
                    self.timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                        guard let self = self, !self.poiNode.isEmpty else {return}
                        self.tempFunc(destNode: node)//error (index out of range)
                        
                    }
                    if self.tempnavFlag == false{
                        self.timer?.invalidate()
                        self.tempFunc(destNode: "SCNVector3(nil,nil,nil)")
                    }
                }
                x=x+1
                alertCtrlr.addAction(action)
                
            }
            let backaction = UIAlertAction(title: "BACK", style: .default)
            alertCtrlr.addAction(backaction)
            self.present(alertCtrlr,animated:true,completion:nil)
        }
        else
        {
            
            tempFunc(destNode: "SCNVector3(0, 0, 0)")
        }
        
    }
   
    func tempFunc(destNode:String) {
        if tempnavFlag{
            for (key,_) in dictPlanes {
                let plane = key as ARAnchor
                self.sceneView.session.remove(anchor: plane)
            }
            dictPlanes = [ARPlaneAnchor:Plane]()
            self.sceneView.debugOptions.remove(
                [ARSCNDebugOptions.showFeaturePoints,ARSCNDebugOptions.showWorldOrigin])
            //                rootPathNode.removeFromParentNode()
            rootTempNode.removeFromParentNode()
            rootConnectingNode.removeFromParentNode()
            
            var minDistanc: Float = 1000
            var nearestNode = SCNNode()
            
            rootPathNode.enumerateChildNodes { (child, _) in
                if !isEqual(n1: origin, n2: child.position) {
                    
                    var dist0 = distanceBetween(n1: cameraLocation, n2: child.position)
                    if minDistanc>dist0 {
                        
                        minDistanc = dist0
                        nearestNode = child
                    }
                }
                //if ((distanceBetween(n1: cameraLocation, n2: child.position))==0){
//                if (distanceBetween(n1: cameraLocation, n2: nearestNode.position)<0.5){
//                        if (cameraLocation.y == nearestNode.position.y){
//                            if (cameraLocation.z == nearestNode.position.z){
//                                 let alert = UIAlertController(title: "Notification", message: "You have reached your location.", preferredStyle: .alert)
//                                 alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
//                                     NSLog("The \"OK\" alert occured.")
//                                 }))
//                                 self.present(alert, animated: true, completion: nil)
//                                 tempnavFlag = false
//                                 stopnavbtn.setTitle("reset", for: .normal)
//                                 //navigationNode.stopTimer()
//                                 //break
//                             }
//                        }
//                     }
            }
            
            stringPathMap["\(cameraLocation)"] = ["\(nearestNode.position)"]
            strNode = "\(cameraLocation)"
            
            retrieveFromDictAndNavigate(destNode:destNode)
        }
        else{
            return
        }
            
    }
    func retrieveFromDictAndNavigate(destNode:String) {
        
        
            rootNavigationNode.enumerateChildNodes { (node, _) in
                node.removeFromParentNode()
            }
            for data in stringPathMap {
                let myVector = self.getVector2FromString(str: data.key)
                dictOfNodes[data.key] = GKGraphNode2D(point: vector2(Float(myVector.x),Float(myVector.z)))
                pathGraph.add([dictOfNodes[data.key]!])
            }
            for data in stringPathMap {
                print(data)
                
                let keyNode = dictOfNodes[data.key]!
                
                for data2 in data.value {
                    keyNode.addConnections(to: [dictOfNodes["\(data2)"]!], bidirectional: true)
                }
            }
            let startKeyVectorString = strNode
            let destKeyVectorString = destNode
            
            let startNodeFromDict = dictOfNodes[startKeyVectorString]
            let destNodeFromDict = dictOfNodes[destKeyVectorString]
            guard let startNode = startNodeFromDict,
                  let destNode = destNodeFromDict else {
                return
            }
            // if (x==path){
                 
        
            if let wayPoint:[GKGraphNode2D] = pathGraph.findPath(from: startNode, to: destNode) as? [GKGraphNode2D] {
                guard !wayPoint.isEmpty else { return }
                var x = wayPoint[0]
                var skipWaypointFlag = true
                for path in wayPoint {
                    
                    if skipWaypointFlag {
                        skipWaypointFlag = false
                        continue
                    }
                    let str = SCNVector3(x.position.x, tempYAxis, x.position.y)
                    let dst = SCNVector3(path.position.x, tempYAxis, path.position.y)
                    let navigationNode = CylinderLine(v1: str, v2: dst, radius: 0.2, UIImageName:"arrow5")
                    navigationNode.startTimer()
                    rootNavigationNode.addChildNode(navigationNode)
                    x = path
                   
                    if tempnavFlag == false{
                        let str = SCNVector3(0,0,0)
                        let dst = SCNVector3(0,0,0)
                        let navigationNode = CylinderLine(v1: str, v2: dst, radius: 0.2, UIImageName:"arrow5")
                        navigationNode.stopTimer()
                    }
                        
                    
                    
                }
                pathGraph = GKGraph()
                stringPathMap.removeValue(forKey: strNode)
                stopnavbtn.isHidden = false
            }
       
        
    }

    
    @IBAction func stopNAV(_ sender: Any){
        if tempnavFlag == false {
            tempnavFlag = true
            stopnavbtn.setTitle("STOP", for: .normal)
            
        }
        //navigationNode.stopTimer()
        else {
            tempnavFlag = false
            stopnavbtn.setTitle("reset", for: .normal)
            
        }
    }
    func addTempNode(hitTestResult:ARHitTestResult) {
        
        let node = SCNNode(geometry: SCNSphere(radius: 0.05))
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        let transform = hitTestResult.worldTransform
        let thirdColumn = transform.columns.3
        node.position = SCNVector3Make(thirdColumn.x, thirdColumn.y, thirdColumn.z)
        if counter == 0 {
            pathNodes[0] = node
            counter = 1
            self.sceneView.scene.rootNode.addChildNode(rootTempNode)
        } else {
            pathNodes[1] = node
            rootTempNode.addChildNode(node)
        }
    }
    
    func addPathNodes(n1:SCNVector3, n2:SCNVector3) {
        
        var node1Position = n1
        var node2Position = n2
        var isNode1exists = false
        var isNode2exists = false
        rootPathNode.enumerateChildNodes({ (child, _) in
            
            // To merge path node less than 0.5 meters
            if !isEqual(n1: origin, n2: child.position) {
                
                let dist0 = distanceBetween(n1: n1, n2: child.position)
                let dist1 = distanceBetween(n1: n2, n2: child.position)
                if(dist0 <= 0.5){
                    node1Position = child.position
                    isNode1exists = true
                }
                if(dist1 <= 0.5){
                    node2Position = child.position
                    isNode2exists = true
                }
            }
        })
        addPathNodeWithConnectingNode(node1Position: node1Position, node2Positon: node2Position)
        mapNodesToStringDict(node1Positon: node1Position, node2Positon: node2Position, isNode1exists: isNode1exists, isNode2exists: isNode2exists)
        
        isNode1exists = false
        isNode2exists = false
    }
    //TO add path nodes and connecting node
    func addPathNodeWithConnectingNode(node1Position:SCNVector3,node2Positon:SCNVector3) {
        
        let pathNode = SCNNode()
        let node = SCNNode(geometry: SCNSphere(radius: 0.05))
        let node2 = SCNNode(geometry: SCNSphere(radius: 0.05))
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        node2.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        node.position = node1Position
        node2.position = node2Positon
        pathNode.addChildNode(node)
        pathNode.addChildNode(node2)
        rootPathNode.addChildNode(pathNode)
        let connectingNode = SCNNode()
        rootConnectingNode.addChildNode(
            connectingNode.buildLineInTwoPointsWithRotation(
                from: node1Position,
                to: node2Positon,
                radius: 0.02,
                color: .cyan))
        
    }
    //TO map nodes into String Dictionary
    func mapNodesToStringDict (node1Positon:SCNVector3,node2Positon:SCNVector3,
                               isNode1exists:Bool,isNode2exists:Bool ) {
        
        let position1String = "\(node1Positon)"
        let position2String = "\(node2Positon)"
        
        if isNode1exists {
            
            var arr = stringPathMap[position1String]
            arr?.append(position2String)
            stringPathMap[position1String] = arr
            
        } else { // Create new node
            stringPathMap[position1String] = [position2String]
        }
        if isNode2exists {
            
            var arr = stringPathMap[position2String]
            arr?.append(position1String)
            stringPathMap[position2String] = arr
            
        } else { // Create new node
            stringPathMap[position2String] = [position1String]
        }
    }
    func removeTempNode() {
        rootTempNode.removeFromParentNode()
        myQueue.async {
            self.rootTempNode.enumerateChildNodes { (node, _) in
                node.removeFromParentNode()
            }
        }
    }
    func distanceBetween(n1:SCNVector3,n2:SCNVector3) -> Float {
        return ((n1.x-n2.x)*(n1.x-n2.x) + (n1.z-n2.z)*(n1.z-n2.z)).squareRoot() // using distance formula to find distance between 2 nodes
    }
    
    func midPointBetween(n1:SCNVector3,n2:SCNVector3) -> SCNVector3 {
        
        return SCNVector3Make(((n1.x+n2.x)/2), ((n1.y+n2.y)/2), ((n1.z+n2.z)/2)) // using mid point formula to determine the mid point of the path
    }
    
    func angleOfInclination(n1:SCNVector3,n2:SCNVector3)-> Float{
        
        let theta = ((n2.z-n1.z)/(n2.x-n1.x)).degreesToRadians // m = tan0 //
        return Float(tan(theta))
    }
    func isEqual(n1:SCNVector3,n2:SCNVector3)-> Bool {
        if (n1.x == n2.x) && (n1.y == n2.y) && (n1.z == n2.z) {
            return true
        } else {
            return false
        }
    }
    func getVector2FromString(str:String) -> vector_double3 {
        
        let xrange = str.index(str.startIndex, offsetBy: 10)...str.index(str.endIndex, offsetBy: -1)
        let str1 = str[xrange]
        
        var x:String = ""
        var y:String = ""
        var z:String = ""
        var counter = 1
        for i in str1 {
            //    print (i)
            if (i == "-" || i == "." || i == "0" || i == "1" || i == "2" || i == "3" || i == "4" || i == "5" || i == "6" || i == "7" || i == "8" || i == "9") {
                switch counter {
                case 1 : x = x + "\(i)"
                case 2 : y = y + "\(i)"
                case 3 : z = z + "\(i)"
                default : break
                }
            } else if (i == ",") {
                counter = counter + 1
            }
        }
        if let xx = Double(x), let yy = Double(y), let zz = Double(z) {
            return vector3(xx, yy, zz)
        }
        return vector_double3()
        //return vector3(Double(x)!,Double(y)!,Double(z)!)
    }
}

