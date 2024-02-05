# frozen_string_literal: true

require 'json'

describe Blueprinter::Reflection do
  let(:category_blueprint) {
    Class.new(Blueprinter::Base) do
      fields :id, :name
    end
  }

  let(:part_blueprint) {
    Class.new(Blueprinter::Base) do
      fields :id, :name

      view :extended do
        field :description
      end
    end
  }

  let(:widget_blueprint) {
    cat_bp = category_blueprint
    part_bp = part_blueprint
    Class.new(Blueprinter::Base) do
      fields :id, :name
      association :category, blueprint: cat_bp

      view :extended do
        association :parts, blueprint: part_bp, view: :extended
      end

      view :extended_plus do
        include_view :extended
        field :foo
        association :foos, blueprint: part_bp
      end

      view :extended_plus_plus do
        include_view :extended_plus
        field :bar
        association :bars, blueprint: part_bp
      end

      view :legacy do
        association :pieces, blueprint: part_bp, source: :parts
      end

      view :aliased_names do
        field :aliased_name, source: :name
        association :aliased_category, blueprint: cat_bp, source: :category
      end

      view :overridden_fields do
        field :name, source: :override_field
        association :category, source: :overridden_category, blueprint: cat_bp
      end
    end
  }

  it 'should list views' do
    expect(widget_blueprint.reflections.keys.sort).to eq [
      :identifier,
      :default,
      :extended,
      :extended_plus,
      :extended_plus_plus,
      :legacy,
      :aliased_names,
      :overridden_fields
    ].sort
  end

  it 'should list fields' do
    expect(part_blueprint.reflections.fetch(:extended).fields.keys.sort).to eq [
      :id,
      :name,
      :description,
    ].sort
  end

  it 'should list fields from included views' do
    expect(widget_blueprint.reflections.fetch(:extended_plus_plus).fields.keys.sort).to eq [
      :id,
      :name,
      :foo,
      :bar,
    ].sort
  end

  it 'should list aliased fields also included in default view' do
    fields = widget_blueprint.reflections.fetch(:aliased_names).fields
    expect(fields.keys.sort).to eq [
      :id,
      :name,
      :aliased_name,
    ].sort
  end

  it "should list overridden fields" do
    fields = widget_blueprint.reflections.fetch(:overridden_fields).fields
    expect(fields.keys.sort).to eq [
      :id,
      :name,
    ].sort
    name_field = fields[:name]
    expect(name_field.name).to eq :override_field
    expect(name_field.display_name).to eq :name
  end

  it 'should list associations' do
    associations = widget_blueprint.reflections.fetch(:default).associations
    expect(associations.keys).to eq [:category]
  end

  it 'should list associations from included views' do
    associations = widget_blueprint.reflections.fetch(:extended_plus_plus).associations
    expect(associations.keys.sort).to eq [:category, :parts, :foos, :bars].sort
  end

  it 'should list associations using custom names' do
    associations = widget_blueprint.reflections.fetch(:legacy).associations
    expect(associations.keys).to eq [:category, :pieces]
    expect(associations[:pieces].display_name).to eq :pieces
    expect(associations[:pieces].name).to eq :parts
  end

  it 'should list aliased associations also included in default view' do
    associations = widget_blueprint.reflections.fetch(:aliased_names).associations
    expect(associations.keys.sort).to eq [
      :category,
      :aliased_category
    ].sort
  end

  it 'should list overridden associations' do
    associations = widget_blueprint.reflections.fetch(:overridden_fields).associations
    expect(associations.keys.sort).to eq [
      :category,
    ].sort
    category_association = associations[:category]
    expect(category_association.name).to eq :overridden_category
    expect(category_association.display_name).to eq :category
  end

  it 'should get a blueprint and view from an association' do
    assoc = widget_blueprint.reflections[:extended].associations[:parts]
    expect(assoc.name).to eq :parts
    expect(assoc.display_name).to eq :parts
    expect(assoc.blueprint).to eq part_blueprint
    expect(assoc.view).to eq :extended
  end
end
