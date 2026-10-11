/*
    SPDX-FileCopyrightText: 2026 Javier O. Cordero Pérez <javiercorderoperez@gmail.com>
    SPDX-License-Identifier: MIT
*/

#include "colorchooserhelper.h"

#include <KAboutData>

#include <QClipboard>
#include <QDebug>
#include <QGuiApplication>
#include <QMimeData>
#include <QUrlQuery>

using namespace Qt::StringLiterals;

#ifdef HAVE_DBUS
#include <QDBusArgument>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusMessage>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QRandomGenerator>

static const QString portalService = u"org.freedesktop.portal.Desktop"_s;
static const QString portalPath = u"/org/freedesktop/portal/desktop"_s;
static const QString requestInterface = u"org.freedesktop.portal.Request"_s;
#endif

QColor ColorChooserHelper::clipboardColor()
{
    const QMimeData *mimeData = QGuiApplication::clipboard()->mimeData(QClipboard::Clipboard);
    if (!mimeData) {
        return {};
    }
    if (mimeData->hasColor()) {
        return mimeData->colorData().value<QColor>();
    }
    return QColor::fromString(mimeData->text().trimmed());
}

bool ColorChooserHelper::canPickScreenColor() const
{
#ifdef HAVE_DBUS
    const QDBusConnectionInterface *interface = QDBusConnection::sessionBus().interface();
    return interface && (interface->isServiceRegistered(portalService) || interface->activatableServiceNames().value().contains(portalService));
#else
    return false;
#endif
}

QUrl ColorChooserHelper::bugReportUrl() const
{
    // The bugs.kde.org form KBugReport opens.
    const KAboutData aboutData = KAboutData::applicationData();
    const QStringList product = aboutData.productName().split(u'/');
    QUrlQuery query;
    query.addQueryItem(u"format"_s, u"guided"_s);
    query.addQueryItem(u"product"_s, product.constFirst());
    if (product.size() == 2) {
        query.addQueryItem(u"component"_s, product.constLast());
    }
    query.addQueryItem(u"version"_s, aboutData.version());

    QUrl url(u"https://bugs.kde.org/enter_bug.cgi"_s);
    url.setQuery(query);
    return url;
}

QUrl ColorChooserHelper::donateUrl() const
{
    // As KHelpMenu::donate().
    return QUrl(u"https://www.kde.org/donate?app="_s + KAboutData::applicationData().componentName());
}

void ColorChooserHelper::copyToClipboard(const QColor &color) const
{
    auto mimeData = new QMimeData;
    mimeData->setColorData(color);
    mimeData->setText(color.name(color.alpha() == 255 ? QColor::HexRgb : QColor::HexArgb));
    QGuiApplication::clipboard()->setMimeData(mimeData, QClipboard::Clipboard);
}

QColor ColorChooserHelper::colorFromClipboard() const
{
    return clipboardColor();
}

void ColorChooserHelper::pickScreenColor()
{
#ifdef HAVE_DBUS
    if (!m_requestPath.isEmpty()) {
        return;
    }

    QDBusConnection bus = QDBusConnection::sessionBus();
    const QString token = u"kcolorchooser%1"_s.arg(QRandomGenerator::global()->generate());
    const QString sender = bus.baseService().mid(1).replace(u'.', u'_');
    m_requestPath = u"%1/request/%2/%3"_s.arg(portalPath, sender, token);

    // Subscribe before calling so the response cannot be missed.
    bus.connect(portalService, m_requestPath, requestInterface, u"Response"_s, this, SLOT(handlePickColorResponse(uint, QVariantMap)));

    QDBusMessage message = QDBusMessage::createMethodCall(portalService, portalPath, u"org.freedesktop.portal.Screenshot"_s, u"PickColor"_s);
    message << QString() << QVariantMap{{u"handle_token"_s, token}};

    auto watcher = new QDBusPendingCallWatcher(bus.asyncCall(message), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher *watcher) {
        watcher->deleteLater();
        if (watcher->isError()) {
            qWarning() << "Could not pick screen color:" << watcher->error().message();
            disconnectRequest();
        }
    });
#endif
}

void ColorChooserHelper::handlePickColorResponse(uint response, const QVariantMap &results)
{
#ifdef HAVE_DBUS
    disconnectRequest();
    if (response != 0) {
        return;
    }

    const QDBusArgument argument = results.value(u"color"_s).value<QDBusArgument>();
    double red = 0;
    double green = 0;
    double blue = 0;
    argument.beginStructure();
    argument >> red >> green >> blue;
    argument.endStructure();

    Q_EMIT screenColorPicked(QColor::fromRgbF(red, green, blue));
#else
    Q_UNUSED(response)
    Q_UNUSED(results)
#endif
}

void ColorChooserHelper::disconnectRequest()
{
#ifdef HAVE_DBUS
    QDBusConnection::sessionBus()
        .disconnect(portalService, m_requestPath, requestInterface, u"Response"_s, this, SLOT(handlePickColorResponse(uint, QVariantMap)));
    m_requestPath.clear();
#endif
}
