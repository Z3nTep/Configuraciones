#!/bin/bash
# Script COMPLETO: KVM en WSL2 (Ubuntu) - Copia, pega y ejecuta

set -e  # Sale si hay error

echo "🚀 INSTALANDO DEPENDENCIAS COMPLETAS PARA KERNEL + KVM..."
sudo apt update
sudo apt install -y build-essential flex bison libssl-dev libelf-dev bc dwarves pahole \
                   git aria2 wget cpu-checker qemu-kvm libvirt-daemon-system \
                   virt-manager bridge-utils libvirt-clients

echo "📥 DESCARGANDO KERNEL WSL2..."
cd ~
rm -rf WSL2-Linux-Kernel *.tar.gz
git clone --depth=1 -b linux-msft-wsl-6.6.y https://github.com/microsoft/WSL2-Linux-Kernel.git
cd WSL2-Linux-Kernel/

echo "⚙️ CONFIGURANDO KERNEL CON KVM PARA XEON..."
cp Microsoft/config-wsl .config

# KVM completo para Intel Xeon
scripts/config --enable KVM
scripts/config --enable KVM_INTEL
scripts/config --enable KVM_GUEST
scripts/config --enable HYPERVISOR_GUEST

# Optimizaciones WSL + Hyper-V
scripts/config --enable ARCH_CPUIDLE_HALTPOLL
scripts/config --enable HYPERV_IOMMU
scripts/config --enable PARAVIRT_CLOCK
scripts/config --enable CPU_IDLE_GOV_HALTPOLL
scripts/config --enable HALTPOLL_CPUIDLE
scripts/config --disable KCSAN

make olddefconfig

echo "🔨 COMPILANDO KERNEL (20-40min en Xeon E5-2698v4)..."
make -j$(nproc) bzImage

echo "💾 COPIANDO KERNEL A WINDOWS..."
WINUSER=$(powershell.exe '$env:USERNAME' | tr -d '\r')
cp arch/x86/boot/bzImage "/mnt/c/Users/$WINUSER/"

echo "📝 CONFIGURANDO .wslconfig..."
cat > "/mnt/c/Users/$WINUSER/.wslconfig" << EOF
[wsl2]
kernel=C:\\Users\\$WINUSER\\bzImage
nestedVirtualization=true
EOF

echo "✅ ¡CONFIGURACIÓN TERMINADA!"
echo ""
echo "🔄 REINICIA WSL DESDE POWERSHELL WINDOWS (COMO ADMIN):"
echo "wsl --shutdown"
echo "Set-VMProcessor -VMName \"WSL\" -ExposeVirtualizationExtensions \$true"
echo "wsl"
echo ""
echo "🧪 LUEGO PRUEBA KVM:"
echo "uname -r"
echo "sudo modprobe kvm_intel"
echo "ls -l /dev/kvm"
echo "sudo kvm-ok"
echo ""
echo "🎉 Si kvm-ok dice OK → KVM FUNCIONA EN virt-manager!"
