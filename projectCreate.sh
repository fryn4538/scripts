#!/bin/sh

function help(){
  echo "usage: projectCreate -l lang -p projectName -c className"
  echo "optional : -g intialise a git repo inside project folder"
  echo "         : -h show this help message"
}

[[ -z $1 ]] && help

git_init='false'

while getopts "l:hgp:c:e:" flag; do
    case "${flag}" in
        g)
            git_init='true'
            ;;
        l)
            lang="${OPTARG}"
            ;;
        p)
            project_name="${OPTARG}"
            ;;
        c)
            class_name="${OPTARG}"
            ;;
        e)
            exe_name="${OPTARG}"
            ;;
        h)
            help
            ;;
    esac
done


function gradle_init(){ # pass project name and class name

    echo "$project_name"
    echo "$class_name"

  [[  -z $project_name || -z $class_name ]] && help && exit

  mkdir -p $project_name || exit
  mkdir -p $project_name/src/main/java
  mkdir -p $project_name/src/main/resources

  (
    echo "bin/*"
    echo ".project"
    echo ".gradle/*"
    echo ".settings/*"
    echo ".classpath"
    echo "build/*"
  ) > $project_name/.gitignore

  (
    echo -e "plugins{"
    echo -e "\tid 'java'"
    echo -e "}"
    echo -e "jar {"
    echo -e "\tmanifest {"
    echo -e "\t\tattributes 'Main-Class': '$class_name'"
    echo -e "\t}\n}\n"
  ) > $project_name/build.gradle

  folder="$(echo $project_name | sed "s/\./\//g" | xargs dirname)"
  class="$(echo $class_name | sed "s/\./\//g" | xargs basename)"
  mkdir -p $project_name/src/main/java/$folder
  touch $project_name/src/main/java/$folder/$class.java
  [ "$git_init" == "true" ] && git init $project_name
}

function cpp_init(){ # pass pname and exe_name

  [[  -z "$project_name" || -z "$exe_name" ]] && help && exit

  mkdir $project_name || exit

  mkdir $project_name/src
  mkdir $project_name/include
  mkdir $project_name/bin
  mkdir $project_name/debug
  touch $project_name/src/main.cc

  (
    echo "cmake_minimum_required(VERSION 2.8.9)"
    echo "project($project_name)"
    echo "include_directories(include)"
    echo 'file(GLOB_RECURSE SOURCES "src/*".cc)'
    echo "add_executable($exe_name \${SOURCES})"
    echo "install(TARGETS $exe_name DESTINATION /usr/bin)"
  ) > $project_name/CMakeLists.txt

  (
    echo "#!/bin/sh"
    echo 'if [[ -z $1 ]]; then'
    echo 'mkdir -p bin'
    echo 'cd bin'
    echo 'cmake ..'
    echo 'make'
    echo 'elif [[ "$1" == "install" ]]; then'
    echo 'mkdir -p bin'
    echo 'cd bin'
    echo 'cmake ..'
    echo 'sudo make install'
    echo 'elif [[ "$1" == "debug" ]]; then'
    echo 'mkdir -p debug'
    echo 'cd debug'
    echo 'cmake -DCMAKE_BUILD_TYPE=Debug ..'
    echo 'make'
    echo 'elif [[ "$1" == "project" ]]; then'
    echo 'mkdir -p bin'
    echo 'cd bin'
    echo 'cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1 ..'
    echo 'cp compile_commands.json ..'
    echo 'fi'
    ) > $project_name/build

  chmod u+x $project_name/build

  (
    echo 'bin/*'
    echo 'debug/*'
    echo 'compile_commands.json'
    echo '.vimspector.json'
    echo '.clangd/*'
  ) > $project_name/.gitignore

  (
    echo '{'
    echo '"configurations": {'
    echo '"Launch": {'
    echo '"adapter": "vscode-cpptools",'
    echo '"configuration": {'
    echo '"request": "launch",'
    echo "\"program\": \"debug/$exe_name\","
    echo "\"cwd\": \"`pwd`\"," >> .vimspector.json
    echo '"externalConsole": true,'
    echo '"MIMode": "gdb"'
    echo '}'
    echo '}'
    echo '}'
    echo '}'
  ) > $project_name/.vimspector.json

  [ "$git_init" == "true" ] && git init $project_name

  cd $project_name && ./build project

}

function py_init(){

  [[  -z "$project_name" ]] && help && exit
  echo $project_name
  mkdir $project_name || exit
  _project_name=$(echo $project_name | sed -e 's/-/_/g')
  mkdir -p $project_name/docs
  mkdir -p $project_name/$_project_name
  mkdir -p project_name/tests
  touch $project_name/LICENSE
  touch $project_name/README.md
  touch $project_name/TODO.md
  touch $project_name/setup.py
  touch $project_name/.gitignore
  touch $project_name/install.sh
  touch $project_name/$_project_name/__init__.py
  touch $project_name/$_project_name/utils.py
  touch $project_name/$_project_name/__main__.py
  [ "$git_init" == "true" ] && git init $project_name

}

function tex_init(){

  [[  -z "$project_name" ]] && help && exit
  echo $project_name
  mkdir $project_name || exit
  touch $project_name/LICENSE
  touch $project_name/README.md
  touch $project_name/TODO.md
  touch $project_name/.gitignore
  touch $project_name/refs.bib
  touch $project_name/bibconfig.bib
  touch $project_name/main.tex

  (
    echo "\documentclass{article}"
    echo "\usepackage[utf8]{inputenc}"
    echo "\usepackage[english]{babel}"
    echo "\title{Title}"
    echo "\author{Fredrik Yngve}"
    echo "\date{Date}"
    echo "\begin{document}"

    echo "\maketitle"
    echo "\section{Section}"
    echo "\bibliographystyle{alpha}"
    echo "\bibliography{bibconfig,refs}"
    echo "\end{document}" 
  ) > $project_name/main.tex

  (
    echo "% See IEEEtran/bibtex/IEEEtran_bst_HOWTO.pdf section VII, or IEEEtran/bibtex/IEEEexample.bib (last part)"
    echo "@IEEEtranBSTCTL{rapport:BSTcontrol,"
    echo "CTLdash_repeated_names = 'no',"
    echo "CTLname_url_prefix = '[Online]. Tillg??nglig:'"
	echo "}"
  ) > $project_name/bibconfig.bib
  [ "$git_init" == "true" ] && git init $project_name
}


case $lang in
  py )
    py_init
    ;;
  c|cpp )
    cpp_init
    ;;
  gradle )
    gradle_init
    ;;
  latex|tex )
    tex_init
    ;;
esac
