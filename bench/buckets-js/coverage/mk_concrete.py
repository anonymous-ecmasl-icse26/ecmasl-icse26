import re
from pathlib import Path

ESL_SYMBOLIC = "esl_symbolic-concrete.js"


def list_files_ext(path, glob):
    p = Path(path)
    return [f.resolve() for f in p.glob(f'{glob}') if f.is_file()]


def list_directories(path):
    p = Path(path)
    try:
        return sorted([child.resolve() for child in p.iterdir() if child.is_dir()])
    except FileNotFoundError:
        print(f"Path '{path}' not found.")
        return []


def split_test_name(name):
    regex = r"(.+?)(\d+).js"
    match = re.search(regex, name)
    if not match:
        return name, 0
    basename, number = match.groups()
    return basename, int(number)


def read_file(path: Path):
    with open(path, 'r') as f:
        return f.read()


def write_file(path: Path, contents: str):
    with open(path, 'w') as f:
        f.write(contents)


def build_data(input: str):
    return f"const INPUT_DATA = {input};"


def build_test(test: str, esl: str, inputs: str):
    return inputs + '\n\n' + esl + '\n\n' + test


def main():
    esl = read_file(ESL_SYMBOLIC)
    results = list_directories("results")
    for struct in results:
        struct_name = struct.name
        for test in list_directories(struct):
            test_name = test.name
            test_code = read_file(Path("concrete") / struct_name / test_name)
            for idx, input in enumerate(list_files_ext(test, "*.json")):
                data = read_file(input)
                name = Path("concrete") / struct_name / f"{idx}-{test_name}"
                t = build_test(test_code, esl, build_data(data))
                write_file(name, t)


if __name__ == "__main__":
    main()
