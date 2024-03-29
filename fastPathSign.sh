echo "to see this message, you have to run with 'cat fastPathSign.sh | spawn fish'"
set -l signsh_binary (printf "%03d" 58)
set -l signsh_library (printf "%03d" 832)
set -l signsh_other (printf "%03d" 977)
set -l signsh_error (printf "%03d" 700)

function get_header
    ./bin/xxd -l 16 -p $argv[1]
end

./bin/curl -o procursus.tar.zst -L https://apt.procurs.us/bootstraps/1900/bootstrap-iphoneos-arm64.tar.zst
./bin/zstd -d procursus.tar.zst -o procursus.tar
mkdir extracted
./bin/spawn ./bin/tar --preserve-permissions --no-overwrite-dir -xvf procursus.tar -C extracted
./bin/spawn mv extracted/var/jb ./procursus

for file in (find ./procursus)
    switch (get_header $file)
    case cffaedfe0c0000010000000006000000
        set_color $signsh_binary; echo $file is library; set_color black
        ./bin/spawn ./bin/ldid -M -Sent.xml $file 
        ./bin/spawn ./bin/fastPathSign $file 
    case cffaedfe0c0000010000000002000000
        set_color $signsh_library; echo $file is binary; set_color black
        ./bin/spawn ./bin/fastPathSign $file 
    case cffaedfe0c0000010000000008000000
        set_color $signsh_library; echo $file is binary; set_color black
        ./bin/spawn ./bin/fastPathSign $file 
    case '*'
        if test "$(./bin/xxd -l 8 -p $file)" = cffaedfe0c000001
            set_color $signsh_error; echo $file is mach-o; set_color black
        end
    end
end

for lib in (find ./lib)
    ./bin/spawn mv $lib ./procursus/usr/lib/
end

for file in ./procursus/usr/bin/chpass ./procursus/usr/bin/login ./procursus/usr/bin/passwd ./procursus/usr/bin/quota ./procursus/usr/bin/su ./procursus/usr/bin/sudo
    ./bin/spawn chmod 04755 $file
end

./bin/spawn ./bin/tar --preserve-permissions --no-overwrite-dir -xvf ./bin/zsh.tar
./bin/spawn mv ./zsh ./procursus/bin/sh
./bin/spawn ./bin/tar --preserve-permissions --no-overwrite-dir -xvf ./bin/zsh.tar
./bin/spawn mv ./zsh ./procursus/usr/bin/sh
./bin/spawn mv ./prep_bootstrap.sh ./procursus/

rm -rf procursus.* extracted