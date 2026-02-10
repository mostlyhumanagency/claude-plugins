// LiftKit Form Component Template
// Copy this to components/contact-form.tsx (or similar) for a reusable form.
//
// What this demonstrates:
// - "use client" directive (required for useState / event handlers)
// - TextInput with different labelPosition variants
// - Select dropdown for categorical choices
// - Form state management with useState
// - Card wrapper with glass material for visual grouping
// - Proper spacing with Column and Row gap props
//
// Why "use client"?
// Next.js App Router defaults to Server Components. Any component that uses
// React hooks (useState, useEffect) or browser event handlers (onChange,
// onSubmit) must be marked as a Client Component with "use client".

"use client";

import { useState } from "react";
import { Button } from "@/registry/nextjs/components/button";
import { Card } from "@/registry/nextjs/components/card";
import { Column } from "@/registry/nextjs/components/column";
import { Row } from "@/registry/nextjs/components/row";
import { Heading } from "@/registry/nextjs/components/heading";
import { Select } from "@/registry/nextjs/components/select";
import { Text } from "@/registry/nextjs/components/text";
import { TextInput } from "@/registry/nextjs/components/text-input";

// Category options for the Select dropdown
const categoryOptions = [
  { value: "general", label: "General Inquiry" },
  { value: "support", label: "Technical Support" },
  { value: "billing", label: "Billing Question" },
  { value: "feedback", label: "Product Feedback" },
];

interface FormData {
  name: string;
  email: string;
  category: string;
  message: string;
}

export function ContactForm() {
  const [formData, setFormData] = useState<FormData>({
    name: "",
    email: "",
    category: "general",
    message: "",
  });

  // Update a single field in form state.
  // This pattern scales well — add new fields without changing the handler.
  const updateField = (field: keyof FormData, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();

    // Validation pattern: check required fields before submitting.
    // For production, consider a library like zod or valibot for schema validation.
    if (!formData.name || !formData.email) {
      // Replace with your toast/notification component
      console.error("Name and email are required");
      return;
    }

    // Replace with your API call
    console.log("Form submitted:", formData);
  };

  return (
    // Glass material gives the form a frosted-glass background,
    // visually separating it from the page surface.
    <Card material="glass" padding="lg">
      <form onSubmit={handleSubmit}>
        <Column gap="md">
          <Heading variant="title-lg-bold">Contact Us</Heading>
          <Text variant="body-md">
            Fill out the form below and we will get back to you shortly.
          </Text>

          {/* labelPosition="top": label appears above the input (default).
              Best for forms where fields are stacked vertically — users
              can scan labels and inputs in a single visual column. */}
          <TextInput
            label="Full Name"
            labelPosition="top"
            placeholder="Jane Doe"
            value={formData.name}
            onChange={(e) => updateField("name", e.target.value)}
            required
          />

          {/* labelPosition="inline": label appears inside the input border.
              Saves vertical space but can be harder to scan in long forms.
              Use for secondary fields or when space is tight. */}
          <TextInput
            label="Email Address"
            labelPosition="inline"
            placeholder="jane@example.com"
            type="email"
            value={formData.email}
            onChange={(e) => updateField("email", e.target.value)}
            required
          />

          {/* Select: dropdown for predefined choices.
              Always provide a meaningful default so the user sees a valid option. */}
          <Select
            label="Category"
            options={categoryOptions}
            value={formData.category}
            onChange={(value) => updateField("category", value)}
          />

          {/* TextInput with multiline for longer text.
              Grows vertically so the user can see their full message. */}
          <TextInput
            label="Message"
            labelPosition="top"
            placeholder="How can we help?"
            value={formData.message}
            onChange={(e) => updateField("message", e.target.value)}
            multiline
            rows={4}
          />

          {/* Button row: primary action on the left, secondary on the right.
              justify="end" pushes buttons to the right, matching form conventions. */}
          <Row gap="sm" justify="end">
            <Button variant="outlined" type="reset">
              Clear
            </Button>
            <Button variant="filled" type="submit">
              Send Message
            </Button>
          </Row>
        </Column>
      </form>
    </Card>
  );
}
