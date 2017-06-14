// Home Access Plus+ for iOS - A native app to access a HAP+ server
// Copyright (C) 2015-2017  Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

//
//  MultisiteTextField.swift
//  HomeAccessPlus
//

import Foundation
import UIKit
import XCGLogger

/// Preventing the various popups (cut, copy, paste, select,
/// select all) from showing when the textbox is tapped once
/// it has focus
///
/// This is used by the multisite textbox, as the picker view
/// that is shown looks after filling in the relevant text. To
/// prevent the user pasting arbitary text in, the popup options
/// need to be disabled
///
/// - author: Jonathan Hart (stuajnht) <stuajnht@users.noreply.github.com>
/// - since: 1.1.0-alpha
/// - version: 1
/// - date: 2017-06-14
///
/// See: https://stackoverflow.com/a/29596354
/// See: https://stackoverflow.com/a/39015132
class MultisiteTextField : UITextField {
    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        logger.debug("Action being attempted for the multisite textbox: \(action)")
        if action == #selector(copy(_:)) || action == #selector(paste(_:)) {
            logger.debug("The action \(action) has been prevented for the multisite textbox")
            return false
        }
        
        logger.debug("The action \(action) has been allowed for the multisite textbox")
        return true
    }
}
