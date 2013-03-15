RELEASE=3.0

PKGVERSION=1.8.0
PKGRELEASE=1
PKGDIR=libiscsi-${PKGVERSION}
PKGSRC=libiscsi-${PKGVERSION}.tar.gz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)

DEBS=									\
	libiscsi-bin_${PKGVERSION}-${PKGRELEASE}_${ARCH}.deb 		\
	libiscsi-dev_${PKGVERSION}-${PKGRELEASE}_${ARCH}.deb 		\
	libiscsi1_${PKGVERSION}-${PKGRELEASE}_${ARCH}.deb 

all: ${DEBS}
	echo ${DEBS}

${DEBS}: ${PKGSRC}
	echo ${DEBS}
	rm -rf ${PKGDIR}
	tar xf ${PKGSRC} 
	cp -a debian ${PKGDIR}/debian
	cat ${PKGDIR}/COPYING >>${PKGDIR}/debian/copyright
	cd ${PKGDIR}; dpkg-buildpackage -rfakeroot -b -us -uc

.PHONY: download
${PKGSRC} download:
	rm -rf ${PKGDIR} libiscsi.git
	git clone git://github.com/sahlberg/libiscsi.git libiscsi.git
	# There is no 1.8.0 tag - so we use master instead
	#cd libiscsi.git; git checkout -b local ${PKGVERSION}
	rsync -a --exclude .git --exclude .gitignore libiscsi.git/ ${PKGDIR} 
	tar czf ${PKGSRC}.tmp  ${PKGDIR}
	rm -rf ${PKGDIR}
	mv ${PKGSRC}.tmp ${PKGSRC}

.PHONY: upload
upload: ${DEBS}
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o rw
	mkdir -p /pve/${RELEASE}/extra
	rm -f /pve/${RELEASE}/extra/libiscsi*.deb
	rm -f /pve/${RELEASE}/extra/Packages*
	cp ${DEBS} /pve/${RELEASE}/extra
	cd /pve/${RELEASE}/extra; dpkg-scanpackages . /dev/null > Packages; gzip -9c Packages > Packages.gz
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o ro

distclean: clean

.PHONY: clean
clean:
	rm -rf *_${ARCH}.deb *.changes *.dsc ${PKGDIR} 

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
