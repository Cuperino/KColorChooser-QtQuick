/*
This file is part of KDE

  Copyright (C) 1998-2000 Waldo Bastian (bastian@kde.org)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#include "colorchooserhelper.h"
#include "kcolorchooser_version.h"

#include <KAboutData>
#include <KLocalizedQmlContext>
#include <KLocalizedString>

#include <QCommandLineParser>
#include <QGuiApplication>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQuickStyle>

#include <iostream>

using namespace Qt::StringLiterals;

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(u"org.kde.desktop"_s);
    }

    KLocalizedString::setApplicationDomain("kcolorchooser");

    KAboutData aboutData(u"kcolorchooser"_s,
                         i18n("KColorChooser"),
                         QStringLiteral(KCOLORCHOOSER_VERSION_STRING),
                         i18n("KDE Color Chooser"),
                         KAboutLicense::MIT,
                         i18n("(c) 2000, Waldo Bastian"));
    aboutData.addAuthor(i18n("Waldo Bastian"), QString(), u"bastian@kde.org"_s);
    aboutData.addAuthor(i18n("Hugo Parente Lima"), i18n("KF5 port"), u"hugo.pl@gmail.com"_s);
    aboutData.addAuthor(i18n("Javier O. Cordero Pérez"), i18n("Qt Quick port"), u"javiercorderoperez@gmail.com"_s);
    aboutData.setTranslator(i18nc("NAME OF TRANSLATORS", "Your names"), i18nc("EMAIL OF TRANSLATORS", "Your emails"));
    KAboutData::setApplicationData(aboutData);

    QCommandLineParser parser;
    parser.setSingleDashWordOptionMode(QCommandLineParser::ParseAsLongOptions);
    aboutData.setupCommandLine(&parser);
    QCommandLineOption print(u"print"_s, i18n("Print the selected color to stdout."));
    parser.addOption(print);
    QCommandLineOption color(u"color"_s, i18n("Set initially selected color."), i18n("color"));
    parser.addOption(color);
    parser.process(app);
    aboutData.processCommandLine(&parser);

    QGuiApplication::setWindowIcon(QIcon::fromTheme(u"kcolorchooser"_s));

    /* Work around https://bugreports.qt.io/browse/QTBUG-120957 */
    app.processEvents();

    QColor initialColor = Qt::white;
    if (parser.isSet(color)) {
        initialColor = QColor(parser.value(color));
    } else if (const QColor clipboardColor = ColorChooserHelper::clipboardColor(); clipboardColor.isValid()) {
        initialColor = clipboardColor;
    }

    QQmlApplicationEngine engine;
    KLocalization::setupLocalizedContext(&engine);
    engine.setInitialProperties({{u"initialColor"_s, initialColor}});
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        [] {
            QCoreApplication::exit(1);
        },
        Qt::QueuedConnection);
    engine.loadFromModule("org.kde.kcolorchooser", "Main");

    const int result = app.exec();

    if (engine.rootObjects().isEmpty()) {
        return result;
    }

    const QColor c = engine.rootObjects().constFirst()->property("selectedColor").value<QColor>();
    if (parser.isSet(print) && c.isValid()) {
        std::cout << c.name().toUtf8().constData() << std::endl;
    }
    return result;
}
