//
//  BarometerStreamHandler.swift
//  flutter_sensors
//
//  Created by A. Clergeot on 17/07/2023
//

import Foundation
import Flutter
import CoreMotion

public class BarometerStreamHandler : NSObject, FlutterStreamHandler {
    public static let SENSOR_ID = 6
    private var altimeterManager: CMAltimeter?
    
    public func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        if isAvailable() {
            self.startUpdates(eventSink: eventSink)
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.stopUpdates()
        return nil
    }
    
    private func initManager() {
        if altimeterManager == nil {
            altimeterManager = CMAltimeter()
        }
    }
    
    private func startUpdates(eventSink:@escaping FlutterEventSink){
        initManager()
        self.altimeterManager?.startRelativeAltitudeUpdates(to: OperationQueue.current!, withHandler: { (data, error) in
            guard error == nil else { return }
            guard let altitudeData = data else { return }
            // Convert from kilopascals to hPa
            let dataArray = [ altitudeData.pressure.doubleValue * 10.0 ]
            SwiftFlutterSensorsPlugin.notify(sensorId: BarometerStreamHandler.SENSOR_ID, sensorData: dataArray, eventSink: eventSink)
        })
    }

    private func stopUpdates(){
        altimeterManager?.stopRelativeAltitudeUpdates()
        altimeterManager = nil
    }

    public func isAvailable() -> Bool {
        return CMAltimeter.isRelativeAltitudeAvailable()
    }
}
