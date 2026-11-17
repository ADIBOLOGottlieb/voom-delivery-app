<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use Illuminate\Http\Request;

class ExpenseController extends Controller
{
    public function index() { $expenses = Expense::latest('spent_on')->paginate(30); $total = Expense::whereBetween('spent_on', [now()->startOfMonth(), now()->endOfMonth()])->sum('amount'); return view('admin.expenses.index', compact('expenses', 'total')); }
    public function create() { return view('admin.expenses.form', ['expense' => new Expense]); }
    public function store(Request $request) { $data = $request->validate(['reason' => ['required','string','max:255'], 'spent_on' => ['required','date'], 'recipient' => ['required','string','max:255'], 'amount' => ['required','integer','min:1']]); Expense::create([...$data, 'created_by' => $request->user()->id]); return redirect()->route('admin.expenses.index')->with('success', 'Dépense enregistrée.'); }
    public function edit(Expense $expense) { return view('admin.expenses.form', compact('expense')); }
    public function update(Request $request, Expense $expense) { $expense->update($request->validate(['reason' => ['required','string','max:255'], 'spent_on' => ['required','date'], 'recipient' => ['required','string','max:255'], 'amount' => ['required','integer','min:1']])); return redirect()->route('admin.expenses.index')->with('success', 'Dépense modifiée.'); }
    public function destroy(Expense $expense) { $expense->delete(); return back()->with('success', 'Dépense supprimée.'); }
}
