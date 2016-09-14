/**
 * ANSI control/colour definitions for Node.js console output.
 * 
 * (C)opyright 2016
 * 
 * This source code is protected by copyright and distributed under license. 
 * Please see the root LICENSE file for terms and conditions.
 *  
 */
exports.code=()=> {
	return({
		reset:"\x1b[0m",
		bright:"\x1b[1m",
		dim:"\x1b[2m",
		underscore:"\x1b[4m",
		blink:"\x1b[5m",
		reverse:"\x1b[7m",
		hidden:"\x1b[8m",
		cursorreset:"\x1b[0;0H",
		clearline:"\x1b[K",
		clearscreen:"\x1b[2J",

		black:"\x1b[30m",
		red:"\x1b[31m",
		green:"\x1b[32m",
		yellow:"\x1b[33m",
		blue:"\x1b[34m",
		magenta:"\x1b[35m",
		cyan:"\x1b[36m",
		white:"\x1b[37m",

		blackb:"\x1b[40m",
		redb:"\x1b[41m",
		greenb:"\x1b[42m",
		yellowb:"\x1b[43m",
		blueb:"\x1b[44m",
		magentab:"\x1b[45m",
		cyanb:"\x1b[46m",
		whiteb:"\x1b[47m"
	});
}
