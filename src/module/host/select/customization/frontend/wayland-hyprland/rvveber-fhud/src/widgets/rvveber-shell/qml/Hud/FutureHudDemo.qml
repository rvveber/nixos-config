import QtQuick
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick3D.Particles3D
import "../Theme"

Item {
    id: root

    property real pulse
    readonly property real phase: pulse * Math.PI * 2

    NumberAnimation on pulse {
        from: 0
        to: 1
        duration: 2600
        loops: Animation.Infinite
    }

    View3D {
        anchors.fill: parent

        environment: ExtendedSceneEnvironment {
            backgroundMode: SceneEnvironment.Transparent
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.VeryHigh
            tonemapMode: SceneEnvironment.TonemapModeFilmic
            vignetteEnabled: true
            vignetteStrength: 0.8
            vignetteRadius: 0.35
        }

        PerspectiveCamera {
            id: camera
            position: Qt.vector3d(Math.sin(root.phase) * 34, 60, 720)
            eulerRotation.x: -5
            clipFar: 3000
        }

        DirectionalLight {
            eulerRotation: Qt.vector3d(-35, -30, 0)
            brightness: 2.4
            color: Appearance.foregroundStrong
            castsShadow: true
            shadowFactor: 80
        }

        PointLight {
            position: Qt.vector3d(0, 0, 160)
            brightness: 120
            quadraticFade: 0.001
            color: Appearance.accent
        }

        PointLight {
            position: Qt.vector3d(-260, 180, -80)
            brightness: 48
            quadraticFade: 0.001
            color: Appearance.warning
        }

        Node {
            id: machine

            eulerRotation.x: -8
            eulerRotation.y: 7

            NumberAnimation on eulerRotation.z {
                from: 0
                to: 360
                duration: 48000
                loops: Animation.Infinite
            }

            Repeater3D {
                model: 18

                Model {
                    required property int index
                    source: "#Cube"
                    position: Qt.vector3d(Math.cos(index * Math.PI * 2 / 18) * 235, Math.sin(index * Math.PI * 2 / 18) * 235, -25 + Math.sin(index * 1.7 + root.phase) * 26)
                    eulerRotation: Qt.vector3d(Math.sin(index * 0.9 + root.phase) * 20, Math.cos(index * 1.3 + root.phase) * 17, index * 20 + 42 + Math.sin(root.phase) * 8)
                    scale: Qt.vector3d(1.45, 0.18, 0.11)
                    pivot: Qt.vector3d(-50, 0, 0)
                    materials: PrincipledMaterial {
                        baseColor: Appearance.surfaceActive
                        metalness: 0.94
                        roughness: 0.19
                        emissiveFactor: Qt.vector3d(0.02, 0.35, 0.42)
                    }
                }
            }

            Repeater3D {
                model: 36

                Model {
                    required property int index
                    source: "#Cylinder"
                    position: Qt.vector3d(Math.cos(index * Math.PI * 2 / 36) * 300, Math.sin(index * Math.PI * 2 / 36) * 300, -55 + Math.sin(index * 0.72 + root.phase) * 12)
                    eulerRotation: Qt.vector3d(78, index % 2 === 0 ? 12 : -12, index * 10)
                    scale: Qt.vector3d(index % 3 === 0 ? 0.11 : 0.055, 0.8, index % 3 === 0 ? 0.11 : 0.055)
                    materials: PrincipledMaterial {
                        baseColor: index % 3 === 0 ? Appearance.foregroundStrong : Appearance.accent
                        metalness: 0.75
                        roughness: 0.24
                        emissiveFactor: index % 3 === 0 ? Qt.vector3d(0.3, 1, 1) : Qt.vector3d(0.02, 0.5, 0.6)
                    }
                }
            }
        }

        Node {
            id: counterRotor

            eulerRotation.x: 16
            eulerRotation.y: -12

            NumberAnimation on eulerRotation.z {
                from: 360
                to: 0
                duration: 17000
                loops: Animation.Infinite
            }

            Repeater3D {
                model: 12

                Model {
                    required property int index
                    source: "#Cube"
                    position: Qt.vector3d(Math.cos(index * Math.PI / 6) * 165, Math.sin(index * Math.PI / 6) * 165, 22)
                    eulerRotation.z: index * 30
                    scale: Qt.vector3d(0.82, 0.045, 0.075)
                    materials: PrincipledMaterial {
                        baseColor: Appearance.foregroundStrong
                        opacity: 0.72
                        emissiveFactor: Qt.vector3d(0.05, 0.85, 1)
                        lighting: PrincipledMaterial.NoLighting
                    }
                }
            }
        }

        Node {
            id: gyroscope

            eulerRotation: Qt.vector3d(62, root.pulse * 360, 18)

            Repeater3D {
                model: 32

                Model {
                    required property int index
                    source: "#Cube"
                    position: Qt.vector3d(Math.cos(index * Math.PI / 16) * 195, Math.sin(index * Math.PI / 16) * 195, 0)
                    eulerRotation.z: index * 11.25 + 90
                    scale: Qt.vector3d(0.34, 0.035, 0.035)
                    materials: PrincipledMaterial {
                        baseColor: Appearance.accent
                        opacity: index % 4 === 0 ? 0.9 : 0.42
                        metalness: 0.7
                        roughness: 0.16
                        emissiveFactor: Qt.vector3d(0.03, 0.65, 0.78)
                    }
                }
            }
        }

        Node {
            id: polarGyroscope

            eulerRotation: Qt.vector3d(root.pulse * -360, 72, -24)

            Repeater3D {
                model: 24

                Model {
                    required property int index
                    source: "#Cube"
                    position: Qt.vector3d(Math.cos(index * Math.PI / 12) * 128, Math.sin(index * Math.PI / 12) * 128, 42)
                    eulerRotation.z: index * 15 + 90
                    scale: Qt.vector3d(0.28, 0.028, 0.028)
                    materials: PrincipledMaterial {
                        baseColor: Appearance.foregroundStrong
                        opacity: index % 3 === 0 ? 0.86 : 0.34
                        lighting: PrincipledMaterial.NoLighting
                        emissiveFactor: Qt.vector3d(0.28, 0.95, 1)
                    }
                }
            }
        }

        Model {
            source: "#Cylinder"
            eulerRotation.x: 90
            scale: Qt.vector3d(1.8 + Math.sin(root.phase) * 0.08, 0.32, 1.8 + Math.sin(root.phase) * 0.08)
            materials: PrincipledMaterial {
                baseColor: Appearance.surface
                metalness: 0.95
                roughness: 0.12
                emissiveFactor: Qt.vector3d(0.01, 0.35, 0.42)
            }
        }

        Model {
            source: "#Sphere"
            scale: Qt.vector3d(1.35 + root.pulse * 0.08, 1.35 + root.pulse * 0.08, 1.35 + root.pulse * 0.08)
            materials: PrincipledMaterial {
                baseColor: Appearance.alpha(Appearance.accent, 0.24)
                opacity: 0.72
                metalness: 0.2
                roughness: 0.08
                emissiveFactor: Qt.vector3d(0.05, 0.9, 1)
            }
        }

        Model {
            source: "#Sphere"
            scale: Qt.vector3d(0.76, 0.76, 0.76)
            materials: PrincipledMaterial {
                baseColor: Appearance.foregroundStrong
                roughness: 0.02
                emissiveFactor: Qt.vector3d(0.45, 1, 1)
            }
        }

        ParticleSystem3D {
            id: particleSystem

            SpriteParticle3D {
                id: particle
                sprite: Texture {
                    source: "../Assets/particle.svg"
                }
                color: Appearance.accent
                colorVariation: Qt.vector4d(0.2, 0.2, 0.2, 0.5)
                maxAmount: 900
                fadeInDuration: 300
                fadeOutDuration: 1400
                billboard: true
            }

            ParticleEmitter3D {
                particle: particle
                position: Qt.vector3d(0, 0, 40)
                scale: Qt.vector3d(3.8, 3.8, 0.3)
                emitRate: 160
                lifeSpan: 3800
                lifeSpanVariation: 900
                particleScale: 2.2
                particleScaleVariation: 1.8
                velocity: VectorDirection3D {
                    direction: Qt.vector3d(0, 18, 8)
                    directionVariation: Qt.vector3d(95, 95, 30)
                }
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "FHUD // QUANTUM APERTURE"
            color: Appearance.foregroundStrong
            font.family: Appearance.fontFamily
            font.pixelSize: 26
            font.bold: true
            font.letterSpacing: 5
            style: Text.Outline
            styleColor: Appearance.accent
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "GPU SCENEGRAPH · 3D PARTICLES · LIVE TELEMETRY CORE"
            color: Appearance.accent
            font.family: Appearance.fontFamily
            font.pixelSize: 11
            font.letterSpacing: 2
        }
    }

    Repeater {
        model: 14

        Rectangle {
            required property int index
            x: root.width * 0.15
            y: root.height * 0.22 + index * 12
            width: root.width * (0.03 + ((index * 17) % 30) / 100)
            height: 1
            color: Appearance.alpha(Appearance.accent, 0.18 + (index % 4) * 0.08)

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                PauseAnimation {
                    duration: index * 83
                }
                NumberAnimation {
                    to: 0.15
                    duration: 120
                }
                NumberAnimation {
                    to: 1
                    duration: 420
                }
                PauseAnimation {
                    duration: 800
                }
            }
        }
    }
}
