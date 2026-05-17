import _ from "../../../web_modules/pkg/lodash.js";
export const defaultOptions = {
  xterm: {fontSize: 13, fontFamily: 'JetBrains Mono, monospace'},
  wettyVoid: 0,
  wettyFitTerminal: true
};
export function loadOptions() {
  try {
    let options = _.isUndefined(localStorage.options) ? defaultOptions : JSON.parse(localStorage.options);
    if (!("xterm" in options)) {
      const xterm = options;
      options = defaultOptions;
      options.xterm = xterm;
    }
    if (!options.xterm.fontFamily) {
      options.xterm.fontFamily = defaultOptions.xterm.fontFamily;
    }
    return options;
  } catch {
    return defaultOptions;
  }
}
