// React 19 Form Component Template
// Copy this to components/contact-form.tsx (or similar) for a form with
// server-side validation, optimistic updates, and progressive enhancement.
//
// What this demonstrates:
// - "use client" directive (required for hooks and event handlers)
// - useActionState for form state management (React 19 replacement for useFormState)
// - useFormStatus for pending UI in a child component
// - useOptimistic for instant feedback before the server responds
// - Progressive enhancement: the form works even with JS disabled
// - Proper TypeScript types for form state, actions, and FormData
//
// Why "use client"?
// Next.js App Router defaults to Server Components. Any component that uses
// React hooks (useState, useEffect, useActionState) or browser event handlers
// (onChange, onSubmit) must be marked as a Client Component with "use client".
//
// How server actions fit in:
// The actual server action lives in a separate file (e.g., actions/contact.ts)
// marked with "use server". This template shows the client-side consumption of
// that action. The server action receives FormData and returns a typed state object.

"use client";

import { useActionState, useOptimistic, useRef } from "react";
import { useFormStatus } from "react-dom";

// -- Types ------------------------------------------------------------------

/** The shape returned by the server action after processing the form. */
interface FormState {
  status: "idle" | "success" | "error";
  message: string;
  errors?: {
    name?: string;
    email?: string;
    message?: string;
  };
}

/**
 * Server action signature. The real implementation lives in a "use server" file.
 *
 * Example server action (actions/contact.ts):
 *
 *   "use server";
 *   export async function submitContact(
 *     prevState: FormState,
 *     formData: FormData,
 *   ): Promise<FormState> {
 *     const name = formData.get("name") as string;
 *     const email = formData.get("email") as string;
 *     if (!email.includes("@")) {
 *       return { status: "error", message: "Validation failed", errors: { email: "Invalid email" } };
 *     }
 *     await db.contacts.create({ name, email, message: formData.get("message") as string });
 *     return { status: "success", message: "Thanks! We will be in touch." };
 *   }
 */
type ServerAction = (
  prevState: FormState,
  formData: FormData,
) => Promise<FormState>;

// -- Placeholder action (replace with your real import) ----------------------

// import { submitContact } from "@/actions/contact";
const submitContact: ServerAction = async (_prev, formData) => {
  // Simulate network delay for demo purposes
  await new Promise((r) => setTimeout(r, 1000));
  const email = formData.get("email") as string;
  if (!email.includes("@")) {
    return {
      status: "error",
      message: "Please fix the errors below.",
      errors: { email: "A valid email is required." },
    };
  }
  return { status: "success", message: "Message sent — we will reply soon!" };
};

// -- Submit button (child component) ----------------------------------------

/**
 * Why a separate component?
 * useFormStatus() reads the pending state of the *nearest parent <form>*.
 * It must be rendered as a *child* of that <form> — calling it in the same
 * component that renders <form> will not work because the hook needs to be
 * inside the form's React subtree.
 */
function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <button
      type="submit"
      disabled={pending}
      className="rounded-md bg-indigo-600 px-4 py-2 text-white hover:bg-indigo-500 disabled:opacity-50"
    >
      {pending ? "Sending..." : "Send Message"}
    </button>
  );
}

// -- Optimistic status banner -----------------------------------------------

interface OptimisticMessage {
  text: string;
  sending: boolean;
}

// -- Main form component ----------------------------------------------------

const initialState: FormState = { status: "idle", message: "" };

export function ContactForm() {
  const formRef = useRef<HTMLFormElement>(null);

  // useActionState wires up the server action with React's transition system.
  // It returns [currentState, formAction, isPending]:
  // - currentState: the latest FormState returned by the server
  // - formAction: a wrapped version of submitContact to pass to <form action={}>
  // - isPending: true while the action is in flight
  const [state, formAction, isPending] = useActionState(
    submitContact,
    initialState,
  );

  // useOptimistic lets us show a success banner *immediately* while the real
  // server response is still in transit. If the server returns an error, React
  // automatically rolls back to the real state.
  const [optimistic, setOptimistic] = useOptimistic<OptimisticMessage>(
    { text: state.message, sending: false },
    (_current, newMessage: string) => ({ text: newMessage, sending: true }),
  );

  // Wrap the form action to inject the optimistic update before submission.
  const handleAction = async (formData: FormData) => {
    setOptimistic("Sending your message...");
    // Reset form on submit attempt — if the action fails, the user can re-fill.
    formRef.current?.reset();
    return formAction(formData);
  };

  return (
    <div className="mx-auto max-w-lg space-y-6 p-6">
      <h2 className="text-2xl font-bold">Contact Us</h2>

      {/* Status banner — shows optimistic message while pending, then real state */}
      {optimistic.text && (
        <div
          role="alert"
          className={`rounded-md p-3 text-sm ${
            optimistic.sending
              ? "bg-blue-50 text-blue-700"
              : state.status === "success"
                ? "bg-green-50 text-green-700"
                : state.status === "error"
                  ? "bg-red-50 text-red-700"
                  : ""
          }`}
        >
          {optimistic.text}
        </div>
      )}

      {/*
        Progressive enhancement:
        Using <form action={handleAction}> instead of onSubmit means the form
        can submit as a standard POST if JavaScript fails to load. React
        enhances it with client-side handling when JS is available.
      */}
      <form ref={formRef} action={handleAction} className="space-y-4">
        {/* Name field */}
        <div>
          <label htmlFor="name" className="block text-sm font-medium">
            Name
          </label>
          <input
            id="name"
            name="name"
            type="text"
            required
            className="mt-1 block w-full rounded-md border px-3 py-2"
          />
          {state.errors?.name && (
            <p className="mt-1 text-sm text-red-600">{state.errors.name}</p>
          )}
        </div>

        {/* Email field */}
        <div>
          <label htmlFor="email" className="block text-sm font-medium">
            Email
          </label>
          <input
            id="email"
            name="email"
            type="email"
            required
            className="mt-1 block w-full rounded-md border px-3 py-2"
          />
          {state.errors?.email && (
            <p className="mt-1 text-sm text-red-600">{state.errors.email}</p>
          )}
        </div>

        {/* Message field */}
        <div>
          <label htmlFor="message" className="block text-sm font-medium">
            Message
          </label>
          <textarea
            id="message"
            name="message"
            rows={4}
            required
            className="mt-1 block w-full rounded-md border px-3 py-2"
          />
          {state.errors?.message && (
            <p className="mt-1 text-sm text-red-600">{state.errors.message}</p>
          )}
        </div>

        {/* Actions row */}
        <div className="flex justify-end gap-3">
          <button
            type="reset"
            className="rounded-md border px-4 py-2 hover:bg-gray-50"
          >
            Clear
          </button>
          {/* SubmitButton is a child of <form> so useFormStatus can read pending state */}
          <SubmitButton />
        </div>
      </form>
    </div>
  );
}
