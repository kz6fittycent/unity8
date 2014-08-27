/*
 * Copyright 2014 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import QtTest 1.0
import Unity.Test 0.1 as UT
import Ubuntu.Components 0.1
import Unity.Application 0.1
import "../../../qml/Stages"

Rectangle {
    color: "red"
    id: root
    width: units.gu(70)
    height: units.gu(70)

    property QtObject fakeApplication: null


    Component {
        id: sessionContainerComponent

        SessionContainer {
            id: sessionContainer
            anchors.fill: parent
        }
    }

    Loader {
        id: sessionContainerLoader
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
        }
        width: units.gu(40)
        sourceComponent: sessionContainerComponent
    }

    Rectangle {
        color: "white"
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: sessionContainerLoader.right
            right: parent.right
        }

        Column {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: units.gu(1) }
            spacing: units.gu(1)
            Row {
                anchors { left: parent.left; right: parent.right }
                CheckBox {
                    id: sessionCheckbox;
                    checked: false;
                    onCheckedChanged: {
                        if (sessionContainerLoader.status !== Loader.Ready)
                            return;

                        if (checked) {
                            var fakeSession = SessionManager.createSession("music-player", Qt.resolvedUrl("../Dash/artwork/music-player-design.png"));
                            fakeSession.manualSurfaceCreation = true;
                            fakeSession.createSurface();
                            sessionContainerLoader.item.session = fakeSession;
                        } else {
                            sessionContainerLoader.item.session.release();
                        }
                    }
                }
                Label { text: "session" }
            }
        }
    }

    SignalSpy {
        id: sessionSpy
        target: SessionManager
        signalName: "sessionStopping"
    }

    UT.UnityTestCase {
        id: testCase
        name: "SessionContainer"

        function init() {
            // reload our test subject to get it in a fresh state once again
            sessionContainerLoader.active = false;
            sessionCheckbox.checked = false;
            sessionContainerLoader.active = true;

            tryCompare(sessionContainerLoader.item, "session", null);
            sessionSpy.clear();
        }

        when: windowShown

        function test_addChildSession_data() {
            return [ { tag: "count=1", count: 1 },
                     { tag: "count=4", count: 4 } ];
        }

        function test_addChildSession(data) {
            sessionCheckbox.checked = true;
            var sessionContainer = sessionContainerLoader.item;
            compare(sessionContainer.childSessions.count(), 0);

            var i;
            var sessions = [];
            for (i = 0; i < data.count; i++) {
                var session = SessionManager.createSession(sessionContainer.session.name + "-Child" + i,
                                                           Qt.resolvedUrl("../Dash/artwork/music-player-design.png"));
                session.createSurface();
                sessionContainer.session.addChildSession(session);
                compare(sessionContainer.childSessions.count(), i+1);

                sessions.push(session);
            }

            for (i = data.count-1; i >= 0; i--) {
                sessions[i].release();
                tryCompareFunction(function() { return sessionContainer.childSessions.count(); }, i);
            }
            tryCompare(sessionSpy, "count", data.count)
        }

        function test_nestedChildSessions_data() {
            return [ { tag: "depth=2", depth: 2 },
                     { tag: "depth=8", depth: 8 }
            ];
        }

        function test_nestedChildSessions(data) {
            sessionCheckbox.checked = true;
            var sessionContainer = sessionContainerLoader.item;
            compare(sessionContainer.childSessions.count(), 0);

            var i;
            var sessions = [];
            var lastSession = sessionContainer.session;
            var delegate;
            var container = sessionContainer;
            for (i = 0; i < data.depth; i++) {
                var session = SessionManager.createSession(lastSession.name + "-Child" + i,
                                                           Qt.resolvedUrl("../Dash/artwork/music-player-design.png"));
                session.createSurface();
                lastSession.addChildSession(session);
                compare(container.childSessions.count(), 1);
                sessions.push(session);

                delegate = findChild(container, "childDelegate0");
                container = findChild(delegate, "sessionContainer");
                lastSession = session;
            }

            for (i = data.depth-1; i >= 0; i--) {
                sessions[i].release();
            }

            tryCompareFunction(function() { return sessionContainer.childSessions.count(); }, 0);
            tryCompare(sessionSpy, "count", data.depth)
        }
    }
}
