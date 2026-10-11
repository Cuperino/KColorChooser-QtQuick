cmake_minimum_required (VERSION 3.16 FATAL_ERROR)

# KDE Application Version, managed by release script
set(RELEASE_SERVICE_VERSION_MAJOR "26")
set(RELEASE_SERVICE_VERSION_MINOR "11")
set(RELEASE_SERVICE_VERSION_MICRO "70")
set(RELEASE_SERVICE_VERSION "${RELEASE_SERVICE_VERSION_MAJOR}.${RELEASE_SERVICE_VERSION_MINOR}.${RELEASE_SERVICE_VERSION_MICRO}")

project(kcolorchooser VERSION ${RELEASE_SERVICE_VERSION})

set(QT_MIN_VERSION     "6.5.0")
set(KF_MIN_VERSION    "6.9.0")
set(KIRIGAMI_ADDONS_MIN_VERSION "1.4.0")

find_package(ECM ${KF_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(ECMInstallIcons)
include(ECMAddAppIcon)
include(KDEInstallDirs)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(KDECMakeSettings)
include(ECMSetupVersion)
include(ECMDeprecationSettings)
include(KDEGitCommitHooks)
include(KDEClangFormat)
file(GLOB_RECURSE ALL_CLANG_FORMAT_SOURCE_FILES *.cpp *.h *.c)
kde_clang_format(${ALL_CLANG_FORMAT_SOURCE_FILES})

find_package(Qt6 ${QT_MIN_VERSION} CONFIG REQUIRED COMPONENTS
  Core
  Gui
  Qml
  Quick
  QuickControls2)
find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS
  CoreAddons
  I18n
  Kirigami)
find_package(KF6KirigamiAddons ${KIRIGAMI_ADDONS_MIN_VERSION} REQUIRED)
set_package_properties(KF6KirigamiAddons PROPERTIES
  TYPE RUNTIME
  PURPOSE "Provides the About pages")

if (UNIX AND NOT APPLE AND NOT ANDROID)
  find_package(Qt6 ${QT_MIN_VERSION} CONFIG REQUIRED COMPONENTS DBus)
  set(HAVE_DBUS TRUE)
endif()

add_definitions(-DQT_NO_URL_CAST_FROM_STRING)
ecm_set_disabled_deprecation_versions(QT 6.9.0
     KF 6.13.0
    )

ecm_setup_version(${RELEASE_SERVICE_VERSION} VARIABLE_PREFIX KCOLORCHOOSER VERSION_HEADER kcolorchooser_version.h)

add_executable(kcolorchooser)
target_sources(kcolorchooser PRIVATE kcolorchooser.cpp colorchooserhelper.cpp colorchooserhelper.h)

set(qml_files
  qml/Main.qml
  qml/ColorChooserPage.qml
  qml/ColorFields.qml
  qml/LuminancePicker.qml
  qml/ColorSwatchGrid.qml
  qml/HueSaturationPicker.qml
  qml/FieldLabel.qml
)
foreach(file IN LISTS qml_files)
  get_filename_component(alias ${file} NAME)
  set_source_files_properties(${file} PROPERTIES QT_RESOURCE_ALIAS ${alias})
endforeach()

qt_policy(SET QTP0001 NEW)
qt_add_qml_module(kcolorchooser
  URI org.kde.kcolorchooser
  QML_FILES ${qml_files}
)

target_link_libraries(kcolorchooser PRIVATE
	Qt::Gui
	Qt::Qml
	Qt::Quick
	Qt::QuickControls2
	KF6::CoreAddons
	KF6::I18n
	KF6::I18nQml
)

if (HAVE_DBUS)
  target_link_libraries(kcolorchooser PRIVATE Qt::DBus)
  target_compile_definitions(kcolorchooser PRIVATE HAVE_DBUS)
endif()

install(TARGETS kcolorchooser  ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
install(PROGRAMS org.kde.kcolorchooser.desktop DESTINATION  ${KDE_INSTALL_APPDIR})

ecm_install_icons(ICONS
  16-apps-kcolorchooser.png
  22-apps-kcolorchooser.png
  DESTINATION ${KDE_INSTALL_ICONDIR}
  THEME hicolor)

install(FILES org.kde.kcolorchooser.appdata.xml  DESTINATION  ${KDE_INSTALL_METAINFODIR})
kde_configure_git_pre_commit_hook(CHECKS CLANG_FORMAT)
ki18n_install(po)
