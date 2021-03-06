// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

class AnchorVisual {
    init() {
        node = nil
        identifier = ""
        cloudAnchor = nil
        localAnchor = nil
        anchorText = ""
    }
    
    var node : SCNNode? = nil
    var identifier : String
    var cloudAnchor : ASACloudSpatialAnchor? = nil
    var localAnchor : ARAnchor? = nil
    var anchorText : String
    var audioURL : String?
//    Custom SCNNode shape here?
}
