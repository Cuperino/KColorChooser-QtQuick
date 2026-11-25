/*
    SPDX-FileCopyrightText: 2026 Javier O. Cordero Pérez <javiercorderoperez@gmail.com>
    SPDX-License-Identifier: MIT
*/

#pragma once

#include <QColor>
#include <QObject>
#include <QQuickItem>
#include <QUrl>
#include <QVariantMap>
#include <qqmlregistration.h>

/*
 * Clipboard, drag and drop, and screen color picking helpers that have no QML equivalent.
 */
class ColorChooserHelper : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool canPickScreenColor READ canPickScreenColor CONSTANT)
    Q_PROPERTY(QUrl bugReportUrl READ bugReportUrl CONSTANT)
    Q_PROPERTY(QUrl donateUrl READ donateUrl CONSTANT)

public:
    using QObject::QObject;

    static QColor clipboardColor();

    bool canPickScreenColor() const;
    QUrl bugReportUrl() const;
    QUrl donateUrl() const;

    Q_INVOKABLE void copyToClipboard(const QColor &color) const;
    Q_INVOKABLE QColor colorFromClipboard() const;
    // Drags color as application/x-color with a width × height swatch as its
    // pixmap, and returns when the drag ends. source loses its mouse grab, since
    // the drag consumes the release.
    Q_INVOKABLE void dragColor(QQuickItem *source, const QColor &color, int width, int height) const;
    Q_INVOKABLE void pickScreenColor();

Q_SIGNALS:
    void screenColorPicked(const QColor &color);

private Q_SLOTS:
    void handlePickColorResponse(uint response, const QVariantMap &results);

private:
    void disconnectRequest();

    QString m_requestPath;
};
