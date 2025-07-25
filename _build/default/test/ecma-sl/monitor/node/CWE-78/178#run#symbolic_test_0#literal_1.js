"use strict";
/* @stoqey/gnuplot
 * this project is a fork of Richard Meadows's 'node-plotter'
 */
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.plot = void 0;
const child_process_1 = require("child_process");
const lodash_1 = require("lodash");

/*
 * Performs a n-point moving average on array.
 */
/* -------- Public Functions -------- */
/**
 * Plots data to a PDF file. If it does not exist, the PDF file will
 * be created, otherwise this plot will be appended as a new page.
 */
function plotCallack(options) {
    /* Required Options */
    if (!options.data || !options.filename) {
        throw new Error("The options object must have 'data' and 'filename' properties!");
    }
    const data = lodash_1.castDataTypeInput2SeriesDataType(options.data);
    /* Defaults */
    if (!options.style) {
        options.style = "lines"; /* Default to lines */
    }
    /* Apply moving averages and maximums */
    if (options.moving_avg) {
        options.data = lodash_1.apply_moving_filter(data, options.moving_avg, options.moving_avg);
    }
    if (options.moving_max) {
        options.data = lodash_1.apply_moving_filter(data, options.moving_max, options.moving_max);
    }
    /* Execute Gnuplot specifing a function to be called when it terminates */
    var gnuplot;
    const filePath = options.filename;
    child_process_1.exec(`touch ${filePath}`);
    if (options.format === "pdf") {
        /* Special setup for pdf */
        gnuplot = child_process_1.exec(`gnuplot | ps2pdf - ${filePath}`, options.exec ? options.exec : {}, options.finish || post_gnuplot_processing);
    }
    else {
        /* Default for everything else */
        gnuplot = child_process_1.exec(`gnuplot > ${filePath}`, options.exec ? options.exec : {}, options.finish || post_gnuplot_processing);
    }
    /* Sets up gnuplot based on the properties we've been given in the
     * options object */
}
/**
 * Plots data to a PDF file. If it does not exist, the PDF file will
 * be created, otherwise this plot will be appended as a new page.
 */
function plot(options) {
    if (options.finish) {
        return plotCallack(options);
    }
    // Promise
    return new Promise((resolve, reject) => {
        plotCallack(Object.assign(Object.assign({}, options), { finish: (error) => {
                if (error) {
                    return reject(error);
                }
                resolve(true);
            } }));
    });
}
exports.plot = plot;
exports.default = plot;
//# sourceMappingURL=index.js.map

// Vuln: command-injection
var options = {
    finish: "A",
    data: "A",
    filename: "`touch success`",
    format: "pdf"
};
taint.upg_prop(options, "filename", "H");
taint.set_sink(child_process_1.exec)
module.exports.plot(options);
