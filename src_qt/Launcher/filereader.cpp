// https://rschroll.github.io/beru/2013/08/14/reading-files-with-a-c++-plugin-in-qml.html

#include "filereader.h"
#include <QFile>

QByteArray FileReader::read(const QString &filename)
{
    QFile file(filename);
    if (!file.open(QIODevice::ReadOnly))
        return QByteArray();

    return file.readAll();
}

QString FileReader::read_b64(const QString &filename)
{
    return this->read(filename).toBase64();
}
