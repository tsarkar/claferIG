/*
 * Copyright (C) 2012 Jimmy Liang <http://gsd.uwaterloo.ca>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to do
 * so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
package org.clafer.ig;

import edu.mit.csail.sdg.alloy4.A4Reporter;
import edu.mit.csail.sdg.alloy4.Err;
import edu.mit.csail.sdg.alloy4.ErrorWarning;
import edu.mit.csail.sdg.alloy4compiler.ast.Command;
import edu.mit.csail.sdg.alloy4compiler.parser.AlloyCompiler;
import edu.mit.csail.sdg.alloy4compiler.parser.CompModule;
import edu.mit.csail.sdg.alloy4compiler.translator.A4Options;
import edu.mit.csail.sdg.alloy4compiler.translator.A4Solution;
import edu.mit.csail.sdg.alloy4compiler.translator.TranslateAlloyToKodkod;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.io.Reader;
import java.io.StringWriter;

public final class AlloyInterface {

    public static String readFull(Reader in, int size) throws IOException {
        char[] buf = new char[size];
        int off = 0;

        while (off < size) {
            int l = in.read(buf, off, size - off);
            if (l == -1) {
                throw new IOException("Unexpected eof");
            }

            off += l;
        }

        return new String(buf);
    }
    // Alloy4 sends diagnostic messages and progress reports to the A4Reporter.
    // By default, the A4Reporter ignores all these events (but you can extend the A4Reporter to display the event for the user)
    private static final A4Reporter rep = new A4Reporter() {

        @Override
        public void warning(ErrorWarning msg) {
            System.err.print("Relevance Warning:\n" + (msg.toString().trim()) + "\n\n");
            System.err.flush();
        }
    };

    public static boolean interact(BufferedReader input) throws IOException {
        String op = input.readLine();
        if (op == null || op.equals("q")) {
            return false;
        } else if (op.equals("n")) {
            // continue
        } else {
            throw new IOException("Unknown op " + op);
        }
        return true;
    }

    public static void main(String[] args) throws IOException, Err {
        BufferedReader input = new BufferedReader(new InputStreamReader(System.in));
        int modelLength = Integer.parseInt(input.readLine());

        String modelVerbatim = readFull(input, modelLength);

        // Parse+typecheck the model
        CompModule world = AlloyCompiler.parse(rep, modelVerbatim);

        // Choose some default options for how you want to execute the commands
        A4Options options = new A4Options();
        options.solver = A4Options.SatSolver.SAT4J;

        for (Command command : world.getAllCommands()) {
            // Execute the command
            A4Solution ans = TranslateAlloyToKodkod.execute_command(rep, world.getAllReachableSigs(), command, options);

            // If satisfiable...
            while (ans.satisfiable()) {

                System.out.println("True");

                // Read the input inside here so that we don't block
                // before computing. Hide some of the latency.
                if (!interact(input)) {
                    return;
                }

                StringWriter xml = new StringWriter();
                ans.writeXML(new PrintWriter(xml), null, null);
                String output = xml.toString();
                System.out.println(output.length());
                System.out.print(output);

                A4Solution nextAns = ans.next();
                if(nextAns == ans) {
                    break;
                }
                ans = nextAns;
            }
        }

        do {
            System.out.println("False");
        } while (interact(input));
    }
}
