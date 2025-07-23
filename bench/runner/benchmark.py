#!/usr/bin/env python3
import subprocess
import argparse
import logging
import shutil
import time
import json
import re

from tabulate import tabulate
from datetime import datetime
from sexpdata import loads
from pathlib import Path


def gen_timestamp():
    tm = time.localtime()  # gets current local time
    return "%04d-%02d-%02d_%02dh%02dm%02ds" % (
        tm.tm_year,
        tm.tm_mon,
        tm.tm_mday,
        tm.tm_hour,
        tm.tm_min,
        tm.tm_sec,
    )


def format_time_hours(t: float):
    return f"({round(t, 2)}s, {round(t/3600, 2)}h)"


def format_solver(st: float, sq: int):
    return f"({round(st, 2)}s, {sq})"


def read_json_file(path):
    with open(path, 'r') as f:
        return json.load(f)


def write_json_file(path, data):
    with open(path, "w") as f:
        json.dump(data, f, indent=2)


def read_sexp_file(path):
    try:
        with open(path, 'r') as f:
            content = f.read()
            parsed = loads(content)
            return parsed
    except Exception as e:
        print(f"Error reading or parsing the file: {e}")
        return None


def sexp_model_to_input(sexp: list):
    assert sexp[0].value() == "model"

    data = {}
    for e in sexp[1:]:
        assert len(e) == 3

        name = e[0].value()
        typ = e[1].value()
        value = e[2]

        data[name] = {
            "type": typ,
            "value": value
        }

    return data


def split_test_name(name):
    regex = r"(.+?)(\d+).js"
    match = re.search(regex, name)
    if not match:
        return name, 0
    basename, number = match.groups()
    return basename, int(number)


def list_directories(path):
    p = Path(path)
    try:
        return sorted([child.resolve() for child in p.iterdir() if child.is_dir()])
    except FileNotFoundError:
        print(f"Path '{path}' not found.")
        return []


def clean_directory(path):
    p = Path(path)
    for i in p.iterdir():
        if i.is_file() or i.is_symlink():
            i.unlink()
        elif i.is_dir():
            shutil.rmtree(i)


def list_files_ext(path, glob):
    p = Path(path)
    return [f.resolve() for f in p.glob(f'{glob}') if f.is_file()]


def parse_coverage_summary(summary_path):
    summary = read_json_file(summary_path)
    total = summary["total"]

    def get(key):
        def pct(v): return f'{v}%'
        return pct(total[key]["pct"])

    line = get("lines")
    branch = get("branches")
    function = get("functions")

    return [line, branch, function]


def witness_index(filename: str):
    match = re.search(r"[witness|input]-(\d+)\.sexp", filename)
    assert match != None
    return int(match.group(1))


def mk_input_dirs(coverage_dir, res):
    json_file = res / "symbolic-execution.json"
    json_obj = read_json_file(json_file)
    test_path = Path(json_obj["filename"])

    if "bug" in test_path.parts:
        test_name = Path(*test_path.parts[-3:])
    else:
        test_name = Path(*test_path.parts[-2:])

    input_dir = coverage_dir / "inputs" / test_name
    input_dir.mkdir(parents=True, exist_ok=True)

    # Make sure to clean any previous inputs
    clean_directory(input_dir)

    return input_dir, test_name


def gen_inputs(coverage_dir, res):
    input_dir, test_name = mk_input_dirs(coverage_dir, res)
    test_suit = res / "test-suite"
    models = list_files_ext(test_suit, "*.sexp")

    for index, sexp_file in enumerate(models):
        sexp = read_sexp_file(sexp_file)
        input_cont = sexp_model_to_input(sexp)
        input_file = input_dir / f"{test_name.stem}-{index}-in.json"
        write_json_file(input_file, input_cont)

    return input_dir, test_name


def rename_folder(original: Path, new: Path):
    if new.exists():
        shutil.rmtree(new)
    original.rename(new)
    return new


def preserve_jest_report(coverage_dir, unique):

    inputs = coverage_dir / "inputs"
    report = coverage_dir / "coverage-report"

    new = coverage_dir / f"coverage-report-{unique}"
    inputs = rename_folder(inputs, new)

    # Save all coverage output files
    files = list_files_ext(report, "*")
    for f in files:
        name = f.name
        f.rename(new / name)

    shutil.rmtree(report)


def run_ecmasl_symbolic(datasets: Path, model: str,
                        test_filter: str, outdir: str,
                        timeout=300):

    cmd = ["dune", "exec", "./main.exe", "--",
           "--dataset-dir", str(datasets),
           "--objmodel", model,
           "--output", str(outdir),
           "--timeout", str(timeout)]

    if test_filter:
        cmd += ["--filter", test_filter]

    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        logging.warning(result.stderr)

    return result.returncode, outdir


def run_ecma_concrete(datasets: Path, test_filter=None):

    def parse_stderr(stderr):
        regex = r"TIME:\|(\d*\.\d+|\d+)\|"
        match = re.search(regex, stderr)
        time, = match.groups()
        return float(time)

    def log_error(cmd, res):
        logging.warning(
            f"\"{' '.join(cmd)}\" returned error code {res.returncode}")
        logging.warning(res.stdout)
        logging.warning(res.stderr)

    def parse_time(cmd, res):
        if res.returncode == 0:
            return parse_stderr(res.stderr)
        else:
            log_error(cmd, res)
            return None

    def round_s(t):
        return "error" if t is None else f"{round(t, 2)}s"

    filter_regex = re.compile(test_filter) if test_filter else None

    coverage_dir = (datasets / "coverage").resolve()
    concrete = (coverage_dir / "concrete").resolve()

    base_cmd = ["/usr/bin/time", "-f", "TIME:|%e|", "ecma-sl", "execute"]

    data = []
    total = 0.0
    sep = "----------"

    logging.info(f"Running ecma-sl concretely on: {concrete}")

    for test_dir in list_directories(concrete):

        struct = test_dir.name
        struct_sum = 0.0

        for test in list_files_ext(test_dir, "*.js"):
            if filter_regex and not re.search(filter_regex, str(test)):
                continue

            logging.info(f"\'ecma-sl execute\'{test}")
            cmd = base_cmd + [str(test)]

            result = subprocess.run(cmd, cwd=test_dir,
                                    capture_output=True, text=True)

            t = parse_time(cmd, result)

            if t is not None:
                struct_sum += t
                total += t

        line = (struct, round_s(struct_sum))
        data.append(line)

    data.append((sep, sep))
    data.append((f"Total ", round_s(total)))

    return data


def run_jest_coverage(datasets: Path, tests: list, cov_target: str):
    pattern = f"/({'|'.join(tests)}).test.js$"
    cmd = ["jest", "--testPathPattern", pattern]

    if cov_target:
        cmd += ["--collectCoverageFrom", cov_target]

    logging.info(f'Running Jest: {cmd}')
    result = subprocess.run(cmd, cwd=datasets, capture_output=True, text=True)

    if result.returncode != 0:
        logging.warning(result.stdout)
        logging.warning(result.stderr)

    return result.returncode


def process_test(test_dir, coverage_dir):
    test = None
    solver = None

    logging.info(f"Generating inputs for {test_dir}")

    se_json = test_dir / "symbolic-execution.json"

    if se_json.is_file():
        input_dir, test = gen_inputs(coverage_dir, test_dir)

        if list_files_ext(input_dir, "*-in.json"):
            test_stats = read_json_file(se_json)
            solver = (test_stats["solver_time"], test_stats["solver_queries"])
        else:
            input_dir.rmdir()
            logging.warning(f"No inputs (-in.json) generated for test: {test}")

    else:
        logging.warning(
            f"Not found: \"{se_json}\"")

    return test, solver


def benchmark_dataset(datasets, results_dirs, test_filter, cov_target):

    filter_regex = re.compile(test_filter) if test_filter else None

    data = []
    for results_d in results_dirs:
        logging.info(f"Benchmarking {results_d}")

        results = Path(results_d).resolve()
        coverage_dir = datasets / "coverage"

        # Generate input files and save tests that didn't error
        tests = []
        solver_time = 0.0
        solver_queries = 0

        # Process each test
        for test_dir in list_directories(results):

            if not filter_regex or re.search(filter_regex, str(test_dir)):

                test, solver_stats = process_test(test_dir, coverage_dir)
                if test and solver_stats:
                    tests.append(test.stem)
                    time, queries = solver_stats
                    solver_time += time
                    solver_queries += queries

        if not tests:
            continue

        # Use Jest to measure coverage
        run_jest_coverage(datasets, tests, cov_target)
        cov_json = coverage_dir / "coverage-report" / "coverage-summary.json"

        # "coverage-summary.json" should always exist even if empty
        cov_summary = parse_coverage_summary(cov_json)

        # Preserve coverage summary and inputs
        preserve_jest_report(coverage_dir, unique=results.stem)

        # Parse execution metrics
        results_json = read_json_file(results / "results.json")

        time = format_time_hours(results_json["time"])
        solver = format_solver(solver_time, solver_queries)
        paths = results_json["paths"]

        # Build benchmarking summary in line format
        line = [datasets.stem, results.stem, time] + \
            [solver] + [paths] + cov_summary

        data.append(line)

    return data


def parse_result_line(line: str):
    regex = r'^Run\s+\d+/\d+\s+(.*?)\s+(Exited|Signaled)\s+(-?\d+).*$'
    match = re.search(regex, line)

    if match:

        filepath, status_type, exit_code_str = match.groups()
        filename = Path(filepath).name
        exit_code = int(exit_code_str)

        if status_type == "Signaled" and exit_code == -7:
            outcome = "timeout"
        elif status_type == "Exited" and exit_code == 0:
            outcome = "success"
        else:
            assert exit_code == 125
            outcome = "error"

        return filename, outcome


def detailed_results(results, test_filter=None):

    def preprocess(filename):
        f = open(filename, 'r')
        file = f.read()
        return re.sub(r'\.js\n', '.js', file)

    def _format_time(t: float, t0: float, s: float):
        time = (t, t-t0, t - (t0 + s))
        time_str = f"({round(t, 2)}s, {round(t - t0, 2)}s, {round(t - (t0 + s), 2)}s)"
        return time, time_str

    def _format_solver(st: float, sq: int):
        solver = (st, sq)
        solver_str = f"({round(st, 2)}s, {sq})"
        return solver, solver_str

    def add2total(total, *args):
        assert len(total) == len(args)
        for i, a in enumerate(args):
            if isinstance(a, tuple):
                total[i] = add2total(total[i], *a)
            else:
                if isinstance(a, str):
                    continue
                total[i] += a
        return total

    def format_total(total):
        def r(t): return f"{round(t, 2)}s"
        time, solver, paths = total
        t1, t2, t3 = time
        _, t_solver = _format_solver(*solver)
        data = [f"({r(t1)}, {r(t2)}, {r(t3)})", t_solver, paths]
        return (f"Total ------", '_', *data)

    def extract_exec_stats(se_json, base, number, setup_times):
        test_stats = read_json_file(se_json)

        st = test_stats["solver_time"]
        sq = test_stats["solver_queries"]
        time = test_stats["execution_time"]

        solver, solver_str = _format_solver(st, sq)

        if number == 0:
            setup_times[base] = time
            time, time_s = _format_time(time, 0, st)
        else:
            setup = setup_times.get(base, 0)
            time, time_s = _format_time(time, setup, st)
        return time, time_s, solver, solver_str

    filter_regex = re.compile(test_filter) if test_filter else None

    results = Path(results).resolve()
    results_file = results / "results.txt"
    file_str = preprocess(results_file)

    data = []
    times = {}
    base = None
    category = None
    total = [[0, 0, 0], [0, 0], 0]

    for line in file_str.splitlines():
        result = parse_result_line(line)
        if not result:
            continue

        name, outcome = result
        if not (filter_regex is None or re.search(filter_regex, name)):
            continue

        time, solver = (0, 0, 0), (0, 0)
        test_dir = results / name
        base, number = split_test_name(name)
        time_s, solver_str = (outcome, f"(-, -)")
        se_json = test_dir / "symbolic-execution.json"
        paths = len(list_files_ext(test_dir / "test-suite", "*.sexp"))

        if se_json.is_file():
            time, time_s, solver, solver_str = extract_exec_stats(
                se_json, base, number, times)

        line = (results.stem, name, time_s, solver_str, paths)
        if base != category:
            if category is not None:
                data.append(format_total(total))
                total = [[0, 0, 0], [0, 0], 0]
            data.append((f"------ {base} ------", '_', '_', '_', '_'))
            category = base

        add2total(total, time, solver, paths)
        data.append(line)
    data.append(format_total(total))

    return results.stem, data


def tabulate_concrete_results(results):
    header = ("Lib", "Time")
    return tabulate(results, headers=header, tablefmt="simple")


def tabulate_detailed_results(results):
    header = ("Results",
              "Test",
              "Time\n( full / - setup / - (setup+solver) )",
              "Solver\n(time / queries)",
              "Paths")

    return tabulate(results, headers=header, tablefmt="simple")


def tabulate_results(results):
    header = ("Dataset",
              "Results",
              "Time",
              "Solver\n(time / queries)",
              "Paths",
              "Line-Cov", "Branch-Cov", "Function-Cov")

    return tabulate(results, headers=header, tablefmt="simple")


def save_table(outdir: Path, name: str, table: str):
    with open(outdir / name, "w") as f:
        f.write(table)


def build_ecmasl():
    this_file = Path(__file__).resolve()
    ecma_root = this_file.parent.parent
    try:
        subprocess.run(["dune", "build"], cwd=ecma_root,
                       check=True, capture_output=True)
        subprocess.run(["dune", "install"], cwd=ecma_root,
                       check=True, capture_output=True)
    except subprocess.CalledProcessError as e:
        logging.error(
            f"Command '{e.cmd}' failed with return code {e.returncode}")
        logging.error(f"stdout:\n{e.stdout}")
        logging.error(f"stderr:\n{e.stderr}")


def parse_args():
    parser = argparse.ArgumentParser(
        description="Benchmark ecma-sl on .js datasets")

    parser.add_argument(
        "datasets", help="Path to the datasets directory. \
          Assumes the existence of a \"test\" folder ", default="../buckets")

    parser.add_argument(
        "--results",
        metavar="ecma-out",
        nargs="+",
        default=[],
        help="Path to one or more dataset results"
    )

    parser.add_argument(
        "--run",
        metavar="objmodel",
        nargs="+",
        choices=["default", "logging", "lifting", "loglifting"],
        help="Specify which object models to run"
    )

    parser.add_argument(
        "--filter",
        metavar="regex",
        type=str,
        help="Run tests whose names match the given pattern"
    )

    parser.add_argument(
        "--out",
        metavar="folder",
        default="results-bench",
        type=str,
        help="Path where the inputs should be saved"
    )

    parser.add_argument(
        "--coverage-target",
        metavar="glob",
        type=str,
        help="Specify Jest's target sources for measuring coverage"
    )

    parser.add_argument(
        '-concrete',
        action='store_true',
        help="Enable concrete execution on the given inputs"
    )

    parser.add_argument(
        '--timeout',
        type=int,
        metavar="seconds",
        default=300,
        help="Specify the timeout in seconds"
    )

    parser.add_argument(
        '-concrete-only',
        action='store_true',
        help="Run ecma-sl concretely and exit"
    )

    return parser, parser.parse_args()


def main():

    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )

    parser, args = parse_args()
    dataset_dir = Path(args.datasets)
    results_dirs = args.results
    test_filter = args.filter
    objmodels = args.run
    outdir = Path(args.out)
    cov_target = args.coverage_target
    concrete = args.concrete
    concrete_only = args.concrete_only
    timeout = args.timeout

    starting_ts = gen_timestamp()

    if not (concrete and concrete_only) and ((results_dirs and objmodels) or (not results_dirs and not objmodels)):
        parser.error(
            "You must provide exactly one of --results or --run")

    if (objmodels):

        logging.info(f"Building ecma-sl")
        build_ecmasl()

        for model in objmodels:
            logging.info(f"Running ecma-sl symbolic -> Objmodel : {model}")
            ecma_out = Path(
                outdir / f'results-{starting_ts}-{model}').resolve()
            ret, res = run_ecmasl_symbolic(dataset_dir / "test",
                                           model,
                                           test_filter,
                                           ecma_out,
                                           timeout)
            assert ret == 0, f"ecma-sl symbolic returned error code {ret}"
            results_dirs.append(res)

    outdir.mkdir(parents=True, exist_ok=True)

    # Concrete stats
    if (concrete):
        concrete_data = [run_ecma_concrete(dataset_dir) if objmodels
                         else run_ecma_concrete(dataset_dir, test_filter=test_filter)]

        for data in concrete_data:
            table = tabulate_concrete_results(data)
            logging.info(f"\n\n{table}\n")
            save_table(outdir, f"table-concrete", table)

        if (concrete_only):
            return

    # Detailed symbolic stats
    detailed_data = [detailed_results(results) if objmodels else
                     detailed_results(results, test_filter)
                     for results in results_dirs]

    for name, data in detailed_data:
        table = tabulate_detailed_results(data)
        logging.info(f"\n\n{table}\n")
        save_table(outdir, f"table-{name}", table)

    # Full dataset coverage and global symbolic stats
    benchmark_data = benchmark_dataset(dataset_dir,
                                       results_dirs,
                                       test_filter,
                                       cov_target)

    benchmark_table = tabulate_results(benchmark_data)
    logging.info(f"\n\n{benchmark_table}\n")
    save_table(outdir, f"table-coverage--{starting_ts}", benchmark_table)


if __name__ == "__main__":

    start = datetime.now()
    main()
    end = datetime.now()

    logging.info(f"Elapsed time: {str(end - start).split('.')[0]}")
