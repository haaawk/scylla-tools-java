#!/bin/bash -e

. /etc/os-release
print_usage() {
    echo "build_rpm.sh -target epel-7-x86_64 --configure-user"
    echo "  --target target distribution in mock cfg name"
    exit 1
}
TARGET=
while [ $# -gt 0 ]; do
    case "$1" in
        "--target")
            TARGET=$2
            shift 2
            ;;
        *)
            print_usage
            ;;
    esac
done

is_redhat_variant() {
    [ -f /etc/redhat-release ]
}
pkg_install() {
    if is_redhat_variant; then
        sudo yum install -y $1
    else
        echo "Requires to install following command: $1"
        exit 1
    fi
}


if [ ! -e dist/redhat/build_rpm.sh ]; then
    echo "run build_rpm.sh in top of scylla-tools-java dir"
    exit 1
fi

if [ "$(arch)" != "x86_64" ]; then
    echo "Unsupported architecture: $(arch)"
    exit 1
fi
if [ -z "$TARGET" ]; then
    if [ "$ID" = "centos" -o "$ID" = "rhel" ] && [ "$VERSION_ID" = "7" ]; then
        TARGET=./dist/redhat/mock/scylla-tools-epel-7-x86_64.cfg
    elif [ "$ID" = "fedora" ]; then
        TARGET=$ID-$VERSION_ID-x86_64
    else
        echo "Please specify target"
        exit 1
    fi
fi

if [[ "$TARGET" = epel-7-x86_64 ]]; then
    TARGET=./dist/redhat/mock/scylla-tools-epel-7-x86_64.cfg
fi

if [ ! -f /usr/bin/mock ]; then
    pkg_install mock
fi
if [ ! -f /usr/bin/git ]; then
    pkg_install git
fi

VERSION=$(./SCYLLA-VERSION-GEN)
SCYLLA_VERSION=$(cat build/SCYLLA-VERSION-FILE)
SCYLLA_RELEASE=$(cat build/SCYLLA-RELEASE-FILE)
git archive --format=tar --prefix=scylla-enterprise-tools-$SCYLLA_VERSION/ HEAD -o build/scylla-enterprise-tools-$VERSION.tar
cp dist/redhat/scylla-tools.spec.in build/scylla-enterprise-tools.spec
sed -i -e "s/@@VERSION@@/$SCYLLA_VERSION/g" build/scylla-enterprise-tools.spec
sed -i -e "s/@@RELEASE@@/$SCYLLA_RELEASE/g" build/scylla-enterprise-tools.spec

sudo mock --buildsrpm --root=$TARGET --resultdir=`pwd`/build/srpms --spec=build/scylla-enterprise-tools.spec --sources=build/scylla-enterprise-tools-$VERSION.tar
sudo mock --rebuild --root=$TARGET --resultdir=`pwd`/build/rpms build/srpms/scylla-enterprise-tools-$VERSION*.src.rpm
