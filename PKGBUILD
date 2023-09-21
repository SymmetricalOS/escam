# Maintainer: SidGames5 <sidgamessendmestuff@gmail.com>
pkgname='escam'
pkgver='0.7.0'
pkgrel=1
epoch=
pkgdesc="Extremely simple command-line app manager"
arch=('x86_64')
url="https://github.com/SymmetricalOS/escam"
license=('GPL-3')
makedepends=('haxe>=4')
backup=('etc/escam/database.json')
source=("$url/archive/refs/tags/$pkgver.tar.gz")
md5sums=('SKIP')

prepare() {
	cd "$pkgname-$pkgver"
	haxelib setup ~/haxe/lib
	haxelib install hxcpp
	haxelib install hx_webserver
}

build() {
	cd "$pkgname-$pkgver"
	haxe build.hxml
}

package() {
	cd "$pkgname-$pkgver"
	install -Dm755 ./bin/Main "$pkgdir/usr/bin/escam"
}
