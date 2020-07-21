//
//  ViewController.swift
//  TaskARApp
//
//  Created by 福島悠樹 on 2020/07/19.
//  Copyright © 2020 福島悠樹. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, EarthDelegate, ARSessionDelegate {
    
    @IBOutlet weak var arScnView: ARSCNView!
    
    var enableHoldEarth:Bool = false
    var holdXPosition:Float = 0.0
    var holdYPosition:Float = 0.0
    
    let defaultConfigration:ARWorldTrackingConfiguration = {
        //cofigrationを生成
        let configration = ARWorldTrackingConfiguration()
        
        //水平面と垂直面を検出する設定
        configration.planeDetection = [.horizontal, .vertical]
        
        //画面上のライトに適応
        configration.isLightEstimationEnabled = true
        
        return configration
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Set the view's delegate
        arScnView.delegate = self
        
        // Show statistics such as fps and timing information
        arScnView.showsStatistics = true
        
        //delegate設定
        EarthMgr.sharedInstance.delegate = self
        
        //特徴点の表示(座標軸の原点を表示)
        //arScnView.debugOptions = [ARSCNDebugOptions.showWorldOrigin]
        
        //デフォルトのライト
        arScnView.autoenablesDefaultLighting = true
        
        //① シーンの作成
        let scene = SCNScene()
        EarthMgr.sharedInstance.setCurrentScene(currentScene: scene)
        
        //②　ノードの作成
        let sphereNode = createSphereNode()
        EarthMgr.sharedInstance.setCurrentNode(currentNode: sphereNode)
        
        //カメラと同じ高さ、水平位置にする
        guard let camera = arScnView.pointOfView else{ return }
        let cameraPos = SCNVector3(0, 0, -1.0)
        var position = camera.convertPosition(cameraPos, to: nil)
        position.y = camera.position.y
        position.x = camera.position.x
        EarthMgr.sharedInstance.getCurrentNode().position = position
        
        //sphereNode.look(at: camera.position)
        EarthMgr.sharedInstance.getCurrentScene().rootNode.addChildNode(EarthMgr.sharedInstance.getCurrentNode())
        //③ 作ったノードをルートノードに追加して紐付ける
        /*
        scene.rootNode.addChildNode(textNode)
        */
        
        //タップした時にコールされる関数を宣言
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(tapped))
        
        //arScnViewに追加
        self.arScnView.addGestureRecognizer(tapGestureRecognizer)
        
        //④ Set the scene to the view
        arScnView.scene = EarthMgr.sharedInstance.getCurrentScene()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //run
        arScnView.session.run(defaultConfigration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        arScnView.session.pause()
    }
    
    /*
    //カメラの画像情報が更新されるたびにcall
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let currentCamera = session.currentFrame?.camera
        let transForm = currentCamera?.transform
        
        print("transForm")
    }
    */
    
    // タップされたときに呼ばれる関数
    @objc func tapped(sender: UITapGestureRecognizer) {
        // タップされた位置を取得
        let tapLocation = sender.location(in: arScnView)
        
        // 第二引数　existingPlaneUsingExtent -> 検出された平面内
        let hitTest = arScnView.hitTest(tapLocation,
                                        types: .existingPlaneUsingExtent)
        // 検知された平面をタップした否かの判定
        if !hitTest.isEmpty {
            // タップした箇所が平面のヒットテストに通ったらアンカーをシーンに追加
            print("ヒットテストOK")
            let anchor = ARAnchor(transform: hitTest.first!.worldTransform) //ワールド座標系に対するヒットテスト結果の位置と方向
            arScnView.session.add(anchor: anchor)
        } else {
            print("ヒットテストNG")
        }
    }
    
    //地球をズームアウトする関数
    func zoomOutEarth(){
        guard let camera=arScnView.pointOfView else { return }                      //現在のカメラのポジション
        
        EarthMgr.sharedInstance.getCurrentNode().position = camera.position
        
        //let targetPosCamera = SCNVector3(0, 0, -3)
        let targetPosCamera = SCNVector3(camera.position.x, camera.position.y, -3)
        let target = camera.convertPosition(targetPosCamera, to: nil)
        let action = SCNAction.move(to: target, duration: 1)
        
        //let action = SCNAction.scale(to: 2, duration: 1)
        EarthMgr.sharedInstance.getCurrentNode().runAction(action)
        
        arScnView.session.run(defaultConfigration)
    }
    
    //地球をズームインする関数
    func zoominEarth(){
        guard let camera=arScnView.pointOfView else { return }                  //現在のカメラのポジション
        
        EarthMgr.sharedInstance.getCurrentNode().position = camera.position
        
        //let targetPosCamera = SCNVector3(0, 0, -0.5)
        let targetPosCamera = SCNVector3(camera.position.x, camera.position.y, -0.5)
        let target = camera.convertPosition(targetPosCamera, to: nil)
        let action = SCNAction.move(to: target, duration: 1)
        
        EarthMgr.sharedInstance.getCurrentNode().runAction(action)
        
        arScnView.session.run(defaultConfigration)
    }
    
    //毎フレームごとに呼ばれる関数
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        if enableHoldEarth==true{
            guard let camera = arScnView.pointOfView else{ return }
            
            //物体をホールドする
            //let cameraPos = SCNVector3(0, 0, -1.0)
            //let cameraPos = SCNVector3(camera.position.x, camera.position.y, -1.0)
            let cameraPos = SCNVector3(holdXPosition, holdYPosition, -1.0)
            let position = camera.convertPosition(cameraPos, to: nil)
            EarthMgr.sharedInstance.getCurrentNode().position = position
            
            arScnView.session.run(defaultConfigration)
        }else if enableHoldEarth==false{
            guard let camera = arScnView.pointOfView else{ return }
            
            //カメラと同じ高さ、水平位置にする
            let cameraPos = SCNVector3(0, 0, -1.0)
            //let cameraPos = SCNVector3(camera.position.x, camera.position.y, -1.0)
            var position = camera.convertPosition(cameraPos, to: nil)
            position.y = camera.position.y
            position.x = camera.position.x
            EarthMgr.sharedInstance.getCurrentNode().position = position
            
            arScnView.session.run(defaultConfigration)
        }
        
    }
    
    //アンカーが追加された時に動くdelegateメソッド(平面検出、水平面検出した時にも呼ばれる)
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        print("アンカーが追加された or 平面検出、水平面検出した")
        
        //平面検出、水平面検出した時は除く
        if (anchor is ARPlaneAnchor){
            print("平面検出、水平面検出した")
            return
        }
        
        //textNodeの追加
        //let textNode = createTextNode()
        //node.addChildNode(textNode)
        /*
        //❤️のNodeの追加
        let heartNode = createHeartNode()
        node.addChildNode(heartNode)
        */
    }
    
    /*
    //ハートのノードの追加
    func createHeartNode()->SCNNode{
        let heartScene = SCNScene(named: "art.scnassets/HEART MODEL/Models")!
        let heartNode = SCNNode()
        
        // PikachuF_ColladaMax.scnファイルの中のchildNodesにピカチューがいるので、取り出して、pikaNodeに追加
        for childNode in heartScene.rootNode.childNodes {
            heartNode.addChildNode(childNode)
        }
        // ピカチューの高さを調整する
        // pikaNodeの境界線の最小値と最大値を取得
        let (min, max) = (heartNode.boundingBox)
        
        // Y軸方向の最大値と最小値の差がデフォルトの高さ
        let h = max.y - min.y
        
        // 0.4メートルを100%としたときの倍率を計算(例：hが1mだったとき、0.4)
        let magnification = 0.4 / h
        
        // x, y, z軸それぞれ上で計算した倍率をかけ算。高さは0.4ｍとなり、x, z軸方向も縦横高さ比を保ったまま拡大or縮小する。
        heartNode.scale = SCNVector3(magnification, magnification, magnification)
        
        return heartNode
    }
    */
    
    func createTextNode() -> SCNNode{
        //②-1 ジオメトリ(形状)の作成
        let textGeometry = SCNText(string: "Good!", extrusionDepth: 1)
        
        //②-2 ジオメトリ(形状)の設定（マテリアル）
        let material = SCNMaterial()
        
        //ジオメトリのマテリアル設定で「赤」を指定してあげる
        material.diffuse.contents = UIColor.red
        textGeometry.materials = [material]
        
        //③-1 ジオメトリを格納するノードを作成
        let textNode = SCNNode(geometry: textGeometry)
        
        //③-2 ジオメトリを格納するノードの設定
        textNode.position = SCNVector3(0, 0, -1) //ノードの座標(X,Y,Z)を調整
        textNode.scale = SCNVector3(0.01 , 0.01, 0.01) //ノードの大きさを調整
        
        return textNode
    }
    
    func createSphereNode() -> SCNNode {
        //②-1 ジオメトリ(形状)の作成
        let sphereGeometry = SCNSphere(radius: 0.1) //半径を設定
        
        //②-2 ジオメトリ(形状)の設定（マテリアル）
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "earth")
        sphereGeometry.materials = [material]
        
        //③-1 ジオメトリを格納するノードを作成
        let sphereNode = SCNNode(geometry: sphereGeometry)
        
        //③-2 ジオメトリを格納するノードの設定
        //sphereNode.position = SCNVector3(-1, 0, -0.5) //ノードの座標を調整
        let rotateAction = SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 4)//回転
        let repeatAction = SCNAction.repeatForever(rotateAction)//繰り返し
        sphereNode.runAction(repeatAction)//回転の繰り返しをRUN
        
        return sphereNode
    }
    
    @IBAction func tappedZoomInBtn(_ sender: Any) {
        self.zoominEarth()
    }
    
    @IBAction func tappedZoomOutBtn(_ sender: Any) {
        self.zoomOutEarth()
    }
    
    @IBAction func tappedHoldBtn(_ sender: Any) {
        guard let camera = arScnView.pointOfView else{ return }

        holdXPosition = camera.position.x
        holdYPosition = camera.position.y
        enableHoldEarth = true
    }
    
    @IBAction func tappedUnholdBtn(_ sender: Any) {
        enableHoldEarth = false
    }
}



